//
//  SLCompatibilityHelper.h
//  Functions that are used to maintain system compatibility between different iOS versions.
//
//  Created by Joshua Seltzer on 10/14/15.
//
//

#import "SLCommonHeaders.h"

// define the core foundation version numbers if they have not already been defined
// http://iphonedevwiki.net/index.php/CoreFoundation.framework
#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1100.00
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_9_0
#define kCFCoreFoundationVersionNumber_iOS_9_0 1200.00
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_10_0
#define kCFCoreFoundationVersionNumber_iOS_10_0 1300.00
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_11_0
#define kCFCoreFoundationVersionNumber_iOS_11_0 1400.00
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_12_0
#define kCFCoreFoundationVersionNumber_iOS_12_0 1500.00
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_13_0
#define kCFCoreFoundationVersionNumber_iOS_13_0 1600.00
#endif

// create definitions for the different versions of iOS that are supported by Sleeper
#define kSLSystemVersioniOS13 kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0
#define kSLSystemVersioniOS12 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_0 && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0)
#define kSLSystemVersioniOS11 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0 && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_12_0)
#define kSLSystemVersioniOS10 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0 && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_0)
#define kSLSystemVersioniOS9 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0 && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0)
#define kSLSystemVersioniOS8 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0 && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0)

// interface for version compatibility functions throughout the application
@interface SLCompatibilityHelper : NSObject

// iOS 8 / iOS 9: modifies a snooze UIConcreteLocalNotification object with the selected snooze time (if applicable)
+ (void)modifySnoozeNotificationForLocalNotification:(UIConcreteLocalNotification *)localNotification;

// iOS 10 / iOS 11: modifies a snooze UNSNotificationRecord object with the selected snooze time (if applicable)
+ (void)modifySnoozeNotificationForNotificationRecord:(UNSNotificationRecord *)notificationRecord;

// Returns a modified NSDate object with an appropriately modified snooze time for a given alarm Id and original date
// Returns nil if no modified snooze date is available
+ (NSDate *)modifiedSnoozeDateForAlarmId:(NSString *)alarmId withOriginalDate:(NSDate *)originalDate;

// iOS 8 / iOS 9: Returns the next skippable alarm local notification.  If there is no skippable notification found, return nil.
+ (UIConcreteLocalNotification *)nextSkippableAlarmLocalNotification;

// iOS 10 / iOS 11: Returns the next skippable alarm notification request given an array of notification requests.
// If there is no skippable notification found, return nil.
+ (UNNotificationRequest *)nextSkippableAlarmNotificationRequestForNotificationRequests:(NSArray *)notificationRequests;

// returns whether or not an alarm is skippable based on the alarm Id
+ (BOOL)isAlarmSkippableForAlarmId:(NSString *)alarmId withNextFireDate:(NSDate *)nextFireDate;

// returns a valid alarm Id for a given alarm
+ (NSString *)alarmIdForAlarm:(Alarm *)alarm;

// returns the appropriate title string for a given alarm object
+ (NSString *)alarmTitleForAlarm:(Alarm *)alarm;

// returns the picker view's background color, which will depend on the iOS version
+ (UIColor *)pickerViewBackgroundColor;

// returns the color of the standard labels used throughout the tweak
+ (UIColor *)defaultLabelColor;

// returns the color of the destructive labels used throughout the tweak
+ (UIColor *)destructiveLabelColor;

// iOS 13: returns the background color used for cells used in the various views
+ (UIColor *)tableViewCellBackgroundColor;

// iOS 10, iOS 11, iOS 12, iOS 13: returns the cell selection background color for cells
+ (UIColor *)tableViewCellSelectedBackgroundColor;

@end