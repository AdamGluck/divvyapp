//
//  DivvyDirectionViewController.m
//  DivvyApp
//
//  Created by Adam Gluck on 7/8/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import "DivvyDirectionViewController.h"

@interface DivvyDirectionViewController () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSMutableArray * stepsArray;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation DivvyDirectionViewController

#pragma mark - Boilerplate
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableView handling
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.directions.count){
        [self fillStepsArray];
        return [self.stepsArray[section] count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary * directionDictionary = self.stepsArray[indexPath.section][indexPath.row];
    NSString * directionString = directionDictionary[@"html_instructions"];
    directionString = [self stringByStrippingHTML:directionString];
    if ([self.stepsArray[indexPath.section] count] - 1 == indexPath.row){
        directionString = [self newLineDestinationWillBeOn:directionString];
    }
    directionString = NSLocalizedString(directionString, nil);
    
    UITextView * cellText = (UITextView *)[cell viewWithTag:1];
    UITextView * detailText = (UITextView *)[cell viewWithTag:2];
    cellText.text = directionString;
    detailText.text = [[NSString alloc] initWithFormat:@"%@ (%@)", NSLocalizedString(directionDictionary[@"distance"][@"text"], nil), NSLocalizedString(directionDictionary[@"duration"][@"text"], nil)];
    
    return cell;
}


-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView * headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 35.0)];
    headerView.backgroundColor = [UIColor colorWithRed:61.0/255.0 green:183.0/255.0 blue:228.0/255.0 alpha:1.0f];
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, headerView.bounds.size.width, 25)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = [self titleForHeaderInSection:section];
    label.font = [UIFont boldSystemFontOfSize:14.0];
    [headerView addSubview:label];
    
    return headerView;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35.0;
}
#pragma mark - UITableView Utilities

-(NSString *) titleForHeaderInSection:(NSInteger)section
{
    NSString * titleString;
    if (section == 0){
        titleString = @"Walking Route";
    } else if (section == 1){
        titleString = @"Biking Route";
    } else {
        titleString = @"Walking Route";
    }
    
    return NSLocalizedString(titleString, nil);
}

-(NSString *) stringByStrippingHTML: (NSString *) string
{
    NSRange r;
    while ((r = [string rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        string = [string stringByReplacingCharactersInRange:r withString:@""];
    return string;
}

-(NSString *) newLineDestinationWillBeOn: (NSString *) string
{
    NSMutableString * mutableString = [[NSMutableString alloc] initWithString:string];
    NSRange r;
    while ((r = [string rangeOfString:@"Destination will be on the" options:NSRegularExpressionSearch]).location != NSNotFound){
        [mutableString insertString:@"\n" atIndex:r.location];
        break;
    }
    
    return mutableString;
}

-(void)loadTableViewData
{
    [self.tableView reloadData];
}

#pragma mark - Property Handling
#pragma mark - Property Utilities 

-(void) fillStepsArray
{
    [self.stepsArray removeAllObjects];
    for (int i = 0; i < 3; i ++){
        [self.stepsArray addObject:self.directions[i][@"steps"]];
    }
}

#pragma mark - Lazy Instantiations

-(NSMutableArray *) stepsArray
{
    if (!_stepsArray){
        _stepsArray = [[NSMutableArray alloc] init];
    }
    return _stepsArray;
}
-(NSArray *) directions
{
    if (!_directions){
        _directions = [[NSArray alloc] init];
    }
    return _directions;
}

@end
