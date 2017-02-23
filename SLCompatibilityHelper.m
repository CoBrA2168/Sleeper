//
//  SLCompatibilityHelper.m
//  Functions that are used to maintain system compatibility between different iOS versions.
//
//  Created by Joshua Seltzer on 10/14/15.
//
//

#import "SLCompatibilityHelper.h"
#import "SLPrefsManager.h"
#import <objc/runtime.h>

@implementation SLCompatibilityHelper

// iOS8/iOS9: returns a modified snooze UIConcreteLocalNotification object with the selected snooze time (if applicable)
+ (UIConcreteLocalNotification *)modifiedSnoozeNotificationForLocalNotification:(UIConcreteLocalNotification *)localNotification
{
    // grab the alarm Id from the notification
    NSString *alarmId = [localNotification.userInfo objectForKey:kSLAlarmIdKey];
    
    // check to see if we have an updated snooze time for this alarm
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (alarmPrefs != nil) {
        // subtract the default snooze time from these values since they have already been added to
        // the fire date
        NSInteger hours = alarmPrefs.snoozeTimeHour - kSLDefaultSnoozeHour;
        NSInteger minutes = alarmPrefs.snoozeTimeMinute - kSLDefaultSnoozeMinute;
        NSInteger seconds = alarmPrefs.snoozeTimeSecond - kSLDefaultSnoozeSecond;
        
        // convert the entire value into seconds
        NSTimeInterval timeInterval = hours * 3600 + minutes * 60 + seconds;
        
        // modify the fire date of the notification
        localNotification.fireDate = [localNotification.fireDate dateByAddingTimeInterval:timeInterval];
    }
    
    // return the modified notification
    return localNotification;
}

// iOS10: returns a modified snooze UNSNotificationRecord object with the selected snooze time (if applicable)
+ (UNSNotificationRecord *)modifiedSnoozeNotificationForNotificationRecord:(UNSNotificationRecord *)notificationRecord
{
    // grab the alarm Id from the notification record
    NSString *alarmId = [notificationRecord.userInfo objectForKey:kSLAlarmIdKey];

    // check to see if we have an updated snooze time for this alarm
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (alarmPrefs != nil) {
        // subtract the default snooze time from these values since they have already been added to
        // the fire date
        NSInteger hours = alarmPrefs.snoozeTimeHour - kSLDefaultSnoozeHour;
        NSInteger minutes = alarmPrefs.snoozeTimeMinute - kSLDefaultSnoozeMinute;
        NSInteger seconds = alarmPrefs.snoozeTimeSecond - kSLDefaultSnoozeSecond;
        
        // convert the entire value into seconds
        NSTimeInterval timeInterval = hours * 3600 + minutes * 60 + seconds;
        
        // modify the trigger date of the notification record
        [notificationRecord setTriggerDate:[notificationRecord.triggerDate dateByAddingTimeInterval:timeInterval]];
    }
    
    // return the modified notification record
    return notificationRecord;
}

// iOS8/iOS9: Returns the next skippable alarm local notification.  If there is no skippable notification found, return nil.
+ (UIConcreteLocalNotification *)nextSkippableAlarmLocalNotification
{
    // create a comparator block to sort the array of notifications
    NSComparisonResult (^notificationComparator) (UIConcreteLocalNotification *, UIConcreteLocalNotification *) =
    ^(UIConcreteLocalNotification *lhs, UIConcreteLocalNotification *rhs) {
        // get the next fire date of the left hand side notification
        NSDate *lhsNextFireDate = [lhs nextFireDateAfterDate:[NSDate date]
                                               localTimeZone:[NSTimeZone localTimeZone]];
        
        // get the next fire date of the right hand side notification
        NSDate *rhsNextFireDate = [rhs nextFireDateAfterDate:[NSDate date]
                                               localTimeZone:[NSTimeZone localTimeZone]];
        
        return [lhsNextFireDate compare:rhsNextFireDate];
    };
    
    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = (SBClockDataProvider *)[objc_getClass("SBClockDataProvider") sharedInstance];
    
    // get the scheduled notifications from the SBClockDataProvider (iOS8) or the SBClockNotificationManager (iOS9)
    NSArray *scheduledNotifications = nil;
    if (kSLSystemVersioniOS9) {
        // grab the shared instance of the clock notification manager for the scheduled notifications
        SBClockNotificationManager *clockNotificationManager = (SBClockNotificationManager *)[objc_getClass("SBClockNotificationManager") sharedInstance];
        scheduledNotifications = [clockNotificationManager scheduledLocalNotifications];
    } else {
        // get the scheduled notifications from the clock data provider
        scheduledNotifications = [clockDataProvider _scheduledNotifications];
    }
    
    // take the scheduled notifications and sort them by earliest date
    NSArray *sortedNotifications = [scheduledNotifications sortedArrayUsingComparator:notificationComparator];
    
    // iterate through all of the notifications that are scheduled
    for (UIConcreteLocalNotification *notification in sortedNotifications) {
        // only continue checking if the given notification is an alarm notification and did not
        // originate from a snooze action
        if ([clockDataProvider _isAlarmNotification:notification] && ![Alarm isSnoozeNotification:notification]) {
            // grab the alarm Id from the notification
            NSString *alarmId = [clockDataProvider _alarmIDFromNotification:notification];
            
            // check to see if this notification is skippable
            if ([SLCompatibilityHelper isAlarmLocalNotificationSkippable:notification forAlarmId:alarmId]) {
                // since the array is sorted we know that this is the earliest skippable notification
                return notification;
            }
        }
    }
    
    // if no skippable notification was found, return nil
    return nil;
}

// iOS10: Returns the next skippable alarm notification request given an array of notification requests.
// If there is no skippable notification found, return nil.
+ (UNNotificationRequest *)nextSkippableAlarmNotificationRequestForNotificationRequests:(NSArray *)notificationRequests
{
    // create a comparator block to sort the array of notification requests
    NSComparisonResult (^notificationRequestComparator) (UNNotificationRequest *, UNNotificationRequest *) =
    ^(UNNotificationRequest *lhs, UNNotificationRequest *rhs) {
        // get the next trigger date of the left hand side notification request
        NSDate *lhsTriggerDate = [((UNLegacyNotificationTrigger *)lhs.trigger) _nextTriggerDateAfterDate:[NSDate date]
                                                                                       withRequestedDate:nil
                                                                                         defaultTimeZone:[NSTimeZone localTimeZone]];
        
        // get the next trigger date of the right hand side notification request
        NSDate *rhsTriggerDate = [((UNLegacyNotificationTrigger *)rhs.trigger) _nextTriggerDateAfterDate:[NSDate date]
                                                                                       withRequestedDate:nil
                                                                                         defaultTimeZone:[NSTimeZone localTimeZone]];
        
        return [lhsTriggerDate compare:rhsTriggerDate];
    };

    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = (SBClockDataProvider *)[objc_getClass("SBClockDataProvider") sharedInstance];
    
    // take the scheduled notifications and sort them by earliest date by using the sort descriptor
    NSArray *sortedNotificationRequests = [notificationRequests sortedArrayUsingComparator:notificationRequestComparator];

    // iterate through all of the notifications that are scheduled
    for (UNNotificationRequest *notificationRequest in sortedNotificationRequests) {
        // only continue checking if the given notification is an alarm notification and did not
        // originate from a snooze action
        if ([clockDataProvider _isAlarmNotificationRequest:notificationRequest] && ![notificationRequest.content isFromSnooze]) {
            // grab the alarm Id from the notification request
            NSString *alarmId = [clockDataProvider _alarmIDFromNotificationRequest:notificationRequest];

            // check to see if this notification request is skippable
            if ([SLCompatibilityHelper isAlarmNotificationRequestSkippable:notificationRequest forAlarmId:alarmId]) {
                // since the array is sorted we know that this is the earliest skippable notification
                return notificationRequest;
            }
        }
    }
    
    // if no skippable notification was found, return nil
    return nil;
}

// returns a valid alarm Id for a given alarm
+ (NSString *)alarmIdForAlarm:(Alarm *)alarm
{
    // the alarm Id we will return
    NSString *alarmId = nil;
    
    // check the version of iOS that the device is running to determine where to get the alarm Id
    if (kSLSystemVersioniOS9 || kSLSystemVersioniOS10) {
        alarmId = alarm.alarmID;
    } else {
        alarmId = alarm.alarmId;
    }
    
    return alarmId;
}

// returns the picker view's background color, which will depend on the iOS version
+ (UIColor *)pickerViewBackgroundColor
{
    // the color to return
    UIColor *color = nil;

    // check the version of iOS that the device is running to determine which color to pick
    if (kSLSystemVersioniOS10) {
        color = [UIColor blackColor];
    } else {
        color = [UIColor whiteColor];
    }
    
    return color;
}

// returns the color of the labels in the picker view
+ (UIColor *)pickerViewLabelColor
{
    // the color to return
    UIColor *color = nil;

    // check the version of iOS that the device is running to determine which color to pick
    if (kSLSystemVersioniOS10) {
        color = [UIColor whiteColor];
    } else {
        color = [UIColor blackColor];
    }
    
    return color;
}

// iOS8/iOS9: helper function that will investigate an alarm local notification and alarm Id to see if it is skippable
+ (BOOL)isAlarmLocalNotificationSkippable:(UIConcreteLocalNotification *)localNotification
                               forAlarmId:(NSString *)alarmId
{
    // grab the attributes for the alarm
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    
    // check to see if the skip functionality has been enabled for the alarm
    if (alarmPrefs && alarmPrefs.skipEnabled && alarmPrefs.skipActivationStatus == kSLSkipActivatedStatusUnknown) {
        // create a date components object with the user's selected skip time to see if we are within
        // the threshold to ask the user to skip the alarm
        NSDateComponents *components= [[NSDateComponents alloc] init];
        [components setHour:alarmPrefs.skipTimeHour];
        [components setMinute:alarmPrefs.skipTimeMinute];
        [components setSecond:alarmPrefs.skipTimeSecond];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        // create a date that is the amount of time ahead of the current date
        NSDate *thresholdDate = [calendar dateByAddingComponents:components
                                                          toDate:[NSDate date]
                                                         options:0];
        
        // get the fire date of the alarm we are checking
        NSDate *alarmFireDate = [localNotification nextFireDateAfterDate:[NSDate date]
                                                           localTimeZone:[NSTimeZone localTimeZone]];
        
        // compare the dates to see if this notification is skippable
        return [alarmFireDate compare:thresholdDate] == NSOrderedAscending;
    } else {
        // skip is not even enabled, so we know it is not skippable
        return NO;
    }
}

// iOS10: helper function that will investigate an alarm notification request and alarm Id to see if it is skippable
+ (BOOL)isAlarmNotificationRequestSkippable:(UNNotificationRequest *)notificationRequest
                                 forAlarmId:(NSString *)alarmId
{
    // grab the attributes for the alarm
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    
    // check to see if the skip functionality has been enabled for the alarm
    if (alarmPrefs && alarmPrefs.skipEnabled && alarmPrefs.skipActivationStatus == kSLSkipActivatedStatusUnknown) {
        // create a date components object with the user's selected skip time to see if we are within
        // the threshold to ask the user to skip the alarm
        NSDateComponents *components= [[NSDateComponents alloc] init];
        [components setHour:alarmPrefs.skipTimeHour];
        [components setMinute:alarmPrefs.skipTimeMinute];
        [components setSecond:alarmPrefs.skipTimeSecond];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        // create a date that is the amount of time ahead of the current date
        NSDate *thresholdDate = [calendar dateByAddingComponents:components
                                                          toDate:[NSDate date]
                                                         options:0];
        
        // get the fire date of the alarm we are checking
        NSDate *nextTriggerDate = [((UNLegacyNotificationTrigger *)notificationRequest.trigger) _nextTriggerDateAfterDate:[NSDate date]
                                                                                                        withRequestedDate:nil
                                                                                                          defaultTimeZone:[NSTimeZone localTimeZone]];
        
        // compare the dates to see if this notification is skippable
        return [nextTriggerDate compare:thresholdDate] == NSOrderedAscending;
    } else {
        // skip is not even enabled, so we know it is not skippable
        return NO;
    }
}

@end