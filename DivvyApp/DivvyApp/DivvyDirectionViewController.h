//
//  DivvyDirectionViewController.h
//  DivvyApp
//
//  Created by Adam Gluck on 7/8/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DivvyDirectionViewController : UIViewController

@property (strong, nonatomic) NSArray * directions;
-(void) loadTableViewData;

@end
