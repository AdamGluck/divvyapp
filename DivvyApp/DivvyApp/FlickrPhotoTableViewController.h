//
//  FlickrPhotoTableViewController.h
//  StanfordPhotos
//
//  Created by Andrew Beinstein on 7/22/13.
//  Copyright (c) 2013 Andrew Beinstein. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlickrFetcher.h"


@interface FlickrPhotoTableViewController : UITableViewController

//@property (strong, nonatomic) NSArray *photos; //of NSDictionary

// These are abstract methods
- (NSString *)setTitleForRow:(NSUInteger)row;
- (NSString *)setDetailForRow:(NSUInteger)row;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;


@end
