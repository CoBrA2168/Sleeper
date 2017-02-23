//
//  SLSBApplication.x
//  Hook into the SBApplication class to modify the snooze notification on iOS8.
//
//  Created by Joshua Seltzer on 2/23/17.
//
//

#import "SLCompatibilityHelper.h"

%hook SBApplication

// iOS8: override to insert our custom snooze time if it was defined
- (void)scheduleSnoozeNotification:(UIConcreteLocalNotification *)notification
{
    // pass in the potentially modified notification object
    %orig([SLCompatibilityHelper modifiedSnoozeNotificationForLocalNotification:notification]);
}

%end

%ctor {
    // only initialize this file if we are on iOS8
    if (kSLSystemVersioniOS8) {
        %init();
    }
}