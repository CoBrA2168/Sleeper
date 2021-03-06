//
//  SLEditDateViewController.h
//
//  Created by Joshua Seltzer on 1/3/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import <UIKit/UIKit.h>

// forward delcare the view controller class so that we can define it in the delegate
@class SLEditDateViewController;

// define the height of the time picker view
#define kSLEditDatePickerViewHeight             216.0

// delegate for the edit date controller
@protocol SLEditDateViewControllerDelegate <NSObject>

// notify the delegate that the date was updated
- (void)SLEditDateViewController:(SLEditDateViewController *)editDateViewController
                   didUpdateDate:(NSDate *)date;

@end

// customized view controller which simply contains a date picker view
@interface SLEditDateViewController : UIViewController

// initialize this controller with an optional initial date
- (instancetype)initWithInitialDate:(NSDate *)initialDate;

// the delegate of this view controller
@property (nonatomic, weak) id <SLEditDateViewControllerDelegate> delegate;

@end
