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

@end

@implementation DivvyDirectionViewController

#pragma mark - boiler plate

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addSwipegestureRecognizer];
}

-(void) addSwipegestureRecognizer{
    UISwipeGestureRecognizer * swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
    swipe.delegate = self;
    [self.view addGestureRecognizer:swipe];
}

-(void) swipeRecognized: (UISwipeGestureRecognizer *) swipe{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 0// [self.stepsArray[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UITextView * cellText = (UITextView *)[cell viewWithTag:1];
    UITextView * detailText = (UITextView *)[cell viewWithTag:2];
    
    NSDictionary * directionDictionary = self.stepsArray[indexPath.section][indexPath.row];
    NSString * directionString = directionDictionary[@"html_instructions"];
    directionString = [self stringByStrippingHTML:directionString];
    cellText.text = directionString;
    
    detailText.text = [[NSString alloc] initWithFormat:@"%@ (%@)", directionDictionary[@"distance"][@"text"], directionDictionary[@"duration"][@"text"]];
    
    return cell;
}

-(NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0){
        return @"First Walking Route";
    } else if (section == 1){
        return @"Biking Route";
    } else {
        return @"End Walking Route";
    }
}

#pragma mark - Table view delegate

#pragma mark - Utility Functions

-(NSString *) stringByStrippingHTML: (NSString *) string {
    NSRange r;
    while ((r = [string rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        string = [string stringByReplacingCharactersInRange:r withString:@""];
    return string;
}

#pragma mark - lazy instantiation

-(NSMutableArray *) stepsArray{
    if (!_stepsArray){
        _stepsArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < 3; i ++){
            [_stepsArray addObject:self.directions[i][@"steps"]];
        }
    }
    
    return _stepsArray;
}
-(NSArray *) directions{
    if (!_directions){
        _directions = [[NSArray alloc] init];
    }
    
    return _directions;
}

@end
