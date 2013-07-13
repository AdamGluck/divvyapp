//
//  DivvyMapViewController.m
//  DivvyApp
//
//  Created by Andrew Beinstein on 7/7/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import "DivvyMapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>
#import "BGLDivvyDataAccess.h"
#import "GoogleBikeRoute.h"
#import "DivvyDirectionViewController.h"

@interface DivvyMapViewController () <BGLDivvyDataAccessDelegate, GoogleBikeRouteDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (strong, nonatomic) BGLDivvyDataAccess * dataAccess;
@property (strong, nonatomic) CLLocation * currentLocation;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) CLRegion *chicagoRegion;

@property (strong, nonatomic) CLLocation *startLocation;
@property (strong, nonatomic) CLLocation *endLocation;

@property (strong,nonatomic) NSMutableArray * directionsArray;
@property (strong, nonatomic) IBOutlet UITableView *enterInstructionsView;

@end

@implementation DivvyMapViewController {
    GMSMapView *mapView_;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.dataAccess = [[BGLDivvyDataAccess alloc] init];
    
    self.dataAccess.delegate = self;
    // for testing
    // "latitude":41.8739580629,"longitude":-87.6277394859 should be the station on State St & Harrison St
    
    [self loadMap];
    
    [self configureTableView];
    
    [self.dataAccess fillStationDataASynchronously];
    
}

#pragma mark - DivvyDataAccessDelegate

-(void) asynchronousFillRequestComplete: (NSArray *) data{
    [self.dataAccess grabNearestStationToDeviceWithOption:kNearestStationAny];
    [self geocodeStartAddress];
}

-(void) nearestStationToDeviceFoundWithStation:(BGLStationObject *)station fromDeviceLocation:(CLLocation *) deviceLocation {
    
    self.currentLocation = deviceLocation;
}

#pragma mark - Geocoding functions

- (void)geocodeStartAddress
{
    [self.geocoder geocodeAddressString:self.startAddress
                               inRegion:self.chicagoRegion
                      completionHandler:^(NSArray *placemarks, NSError *error) {
                          NSLog(@"Start geocode completed");
                          self.startLocation = ((CLPlacemark *)placemarks[0]).location;
                          [self addMarkerAtLocation:self.startLocation withTitle:@"Start"];
                          [self geocodeEndAddress];
                          if (error) {
                              NSLog(@"Error in geocoder: %@", error);
                          }
                      }];
    

}

- (void)geocodeEndAddress
{
    [self.geocoder geocodeAddressString:self.endAddress
                               inRegion:self.chicagoRegion
                      completionHandler:^(NSArray *placemarks, NSError *error) {
                          NSLog(@"End geocode completed");
                          self.endLocation = ((CLPlacemark *)placemarks[0]).location;
                          [self addMarkerAtLocation:self.endLocation withTitle:@"End"];
                          [self findStations];
                          if (error) {
                              NSLog(@"Error in geocoder: %@", error);
                          }
                      }];
}

- (void)findStations
{
    BGLStationObject *pickupBikeStation = [self.dataAccess grabNearestStationTo:self.startLocation withOption:kNearestStationWithBike];
    
    BGLStationObject *dropoffBikeStation = [self.dataAccess grabNearestStationTo:self.endLocation withOption:kNearestStationOpen];
    
    NSString * startLocationString = [[NSString alloc] initWithFormat:@"%f,%f", self.startLocation.coordinate.latitude, self.startLocation.coordinate.longitude];
    NSString * pickupBikeStationString = [[NSString alloc] initWithFormat:@"%f,%f", pickupBikeStation.latitude, pickupBikeStation.longitude];
    NSString * dropoffBikeStationString = [[NSString alloc] initWithFormat:@"%f,%f", dropoffBikeStation.latitude, dropoffBikeStation.longitude];
    NSString * endLocationString = [[NSString alloc] initWithFormat:@"%f,%f", self.endLocation.coordinate.latitude, self.endLocation.coordinate.longitude];
    
    GoogleBikeRoute * routeFromStartLocationToPickUpBikeStation = [[GoogleBikeRoute alloc] initWithWaypoints:@[startLocationString, pickupBikeStationString] sensorStatus:YES andDelegate:self];
    [routeFromStartLocationToPickUpBikeStation goWithTransportationType:kTransportationTypeWalking];
    
    GoogleBikeRoute * routeFromPickUpBikeStationToDropOffBikeStation = [[GoogleBikeRoute alloc] initWithWaypoints:@[pickupBikeStationString, dropoffBikeStationString] sensorStatus:YES andDelegate:self];
    [routeFromPickUpBikeStationToDropOffBikeStation goWithTransportationType:kTransportationTypeBiking];
    
    GoogleBikeRoute * routeFromDropOffToEndDestination = [[GoogleBikeRoute alloc] initWithWaypoints:@[dropoffBikeStationString, endLocationString] sensorStatus:YES andDelegate:self];
    [routeFromDropOffToEndDestination goWithTransportationType:kTransportationTypeWalking];
    
    [self addMarkerForStation:pickupBikeStation];
    [self addMarkerForStation:dropoffBikeStation];
    
}

#pragma mark - map drawing functions
- (void)loadMap
{
    NSLog(@"initial self.view.subviews = %@", self.view.subviews);

    NSLog(@"Loading map view");
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:41.8739580629 longitude:-87.6277394859 zoom:12]; // Chicago (zoomed out)
    mapView_ = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
    mapView_.myLocationEnabled = YES;
    
    //self.view = mapView_;
    [self.view insertSubview:mapView_ atIndex:0];
    NSLog(@"mapkit subviews = %@ or %@", self.view.subviews, mapView_.subviews);
}

// Adds a Google Maps marker at a station
- (void)addMarkerForStation:(BGLStationObject *)station
{
    GMSMarker *marker = [[GMSMarker alloc] init];
    CLLocationDegrees latitude = station.latitude; 
    CLLocationDegrees longitude = station.longitude; 
    marker.position = CLLocationCoordinate2DMake(latitude, longitude);
    marker.title = station.stationName; 
    marker.map = mapView_;
}

- (void)addMarkerAtLocation:(CLLocation *)location withTitle:(NSString *)title
{
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = location.coordinate;
    marker.title = title;
    marker.map = mapView_;
}


#pragma mark - GoogleBikeRouteDelegate functions

-(void) routeWithPolyline: (GMSPolyline *) polyline{
    polyline.map = mapView_;
}


-(void) directionsFromServer: (NSDictionary *) directionsDictionary{
   
    NSDictionary * routesDictionary = directionsDictionary[@"routes"][0];
    NSDictionary * legsDictionary = routesDictionary[@"legs"][0];
    NSLog(@"directions from server called");
    [self.directionsArray addObject:legsDictionary];
    
}


#pragma mark - Lazy Instantiations

- (NSString *)startAddress
{
    if (!_startAddress) _startAddress = [[NSString alloc] init];
    return _startAddress;
}

- (NSString *)endAddress
{
    if (!_endAddress) _endAddress = [[NSString alloc] init];
    return _endAddress;
}

- (CLLocation *)startLocation
{
    if (!_startLocation) _startLocation = [[CLLocation alloc] init];
    return _startLocation;
}

- (CLLocation *)endLocation
{
    if (!_endLocation) _endLocation = [[CLLocation alloc] init];
    return _endLocation;
}

- (CLGeocoder *)geocoder
{
    if (!_geocoder) _geocoder = [[CLGeocoder alloc] init];
    return _geocoder;
}

- (CLRegion *)chicagoRegion
{
    if (!_chicagoRegion) {
        NSLog(@"Constructing chicago region");
        CLLocationCoordinate2D chicago = CLLocationCoordinate2DMake(41.8500, 87.6500);
        _chicagoRegion = [[CLRegion alloc] initCircularRegionWithCenter:chicago radius:100 identifier:@"Chicago"];
    }
    return _chicagoRegion;
}

-(NSMutableArray *) directionsArray{
    
    if (!_directionsArray){
        _directionsArray = [[NSMutableArray alloc] init];
    }
    
    return _directionsArray;
}

#pragma mark - Storyboard Functions
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([self.directionsArray count])
        ((DivvyDirectionViewController *) segue.destinationViewController).directions = self.directionsArray;
    
}

#pragma mark - UITableView Configuration

-(void) configureTableView{
    self.enterInstructionsView.backgroundColor = [UIColor clearColor];
    
}


#pragma mark - UITableViewDelegate Functions



#pragma mark - UITableViewDataSourceDelegate Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog(@"number of sections in tableview called");
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"numer of rows in section called");
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"tableview allocated");
    static NSString *CellIdentifier = @"enterLocationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UIImageView * backGroundView = [[UIImageView alloc] initWithFrame:cell.frame];
    backGroundView.backgroundColor = [UIColor blackColor];
    backGroundView.alpha = .6f;
    cell.backgroundView = backGroundView;
    
    return cell;
}



@end
