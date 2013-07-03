//
//  ViewController.m
//  DivvyApp
//
//  Created by Adam Gluck on 7/2/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import "ViewController.h"
#import "BGLDivvyDataAccess.h"

@interface ViewController () <BGLDivvyDataAccessDelegate>{
    int count;
}

@property (strong, nonatomic) BGLDivvyDataAccess * dataAccess;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSLog(@"view did load called");
    self.dataAccess = [[BGLDivvyDataAccess alloc] init];
    
    self.dataAccess.delegate = self;
    self.dataAccess.autoRefresh = YES;
    //[data fillStationDataASynchroniously];
    
    //NSLog(@"%@", data.stationData);
}

-(void) asynchroniousFillRequestComplete: (NSArray *) data{
    count++;
    if (count == 5)
        self.dataAccess.autoRefresh = NO;
}

-(void) requestFailedWithError:(NSError *)error{
    NSLog(@"ERROR!!!");
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
