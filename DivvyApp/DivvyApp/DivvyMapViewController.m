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
#import <AddressBookUI/AddressBookUI.h>
//#import <QuartzCore/QuartzCore.h>

@interface DivvyMapViewController () <BGLDivvyDataAccessDelegate, GoogleBikeRouteDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate>{
    int polylineCount;
}

// grabbing global location data properties
@property (strong, nonatomic) BGLDivvyDataAccess * dataAccess;
@property (strong, nonatomic) CLLocation * currentLocation;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) CLRegion *chicagoRegion;
@property (strong, nonatomic) CLLocationManager * locationManager;

// start location end location properties
@property (strong, nonatomic) CLLocation *startLocation;
@property (strong, nonatomic) CLLocation *endLocation;
@property (strong, nonatomic) IBOutlet UITextField *startLocationField;
@property (strong, nonatomic) IBOutlet UITextField *endLocationField;

// properties that are used to store and display data about directions
@property (strong, nonatomic) NSArray * displayedData; // this holds suggested directions to display in the enterInstructionsView
@property (strong,nonatomic) NSMutableArray * directionsArray; // this holds the direction data returned from google maps to be displayed in the UITableView on the next screen
@property (strong, nonatomic) IBOutlet UITableView *enterInstructionsView;

// barbuttonitems 
@property (strong, nonatomic) IBOutlet UIBarButtonItem *goBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *listBarButtonItem;
@property (strong, nonatomic) IBOutlet UIView *barHolderView;

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
    [self configureBarHolderView];
    [self configureNavigationBar];
    [self configureLocationManager];
    [self loadMap];
    [self configureTableView];
    
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];*/
    
    [self.dataAccess fillStationDataASynchronously]; // so we can use this data later
    
    
    [self geocodeStartAddress];
}


#pragma mark - Geocoding functions

-(void) geocodeAddressStringToDisplay: (NSString *) addressString{
    [self.geocoder geocodeAddressString:addressString completionHandler:^(NSArray *placemarks, NSError *error){
        self.displayedData = placemarks;
        [self.enterInstructionsView reloadData];
        if (error) {
            NSLog(@"Error in geocoder: %@", error);
        }
    }];
    
}
- (void)geocodeStartAddress
{
    NSLog(@"About to geocode start address");
    [self.geocoder geocodeAddressString:self.startAddress
                               inRegion:self.chicagoRegion
                      completionHandler:^(NSArray *placemarks, NSError *error) {
                          NSLog(@"In start geocode completion handler");
                          if (error) {
                              NSLog(@"Error in geocoder: %@", error);
                              NSString *message = [NSString stringWithFormat:@"Sorry! We could not locate your start address: %@. Please go back and try again!", self.startAddress];
                              [self alertUserToErrorWithMessage:message];
                          } else {
                              self.startLocation = ((CLPlacemark *)placemarks[0]).location;
                              [self addMarkerAtLocation:self.startLocation withTitle:@"Start"];
                              [self geocodeEndAddress];
                          }

                      }];
    

}

- (void)geocodeEndAddress
{
    NSLog(@"about to geocode end address");
    [self.geocoder geocodeAddressString:self.endAddress
                               inRegion:self.chicagoRegion
                      completionHandler:^(NSArray *placemarks, NSError *error) {
                          if (error) {
                              NSLog(@"Error in geocoder: %@", error);
                              NSString *message = [NSString stringWithFormat:@"Sorry! We could not locate your end address: %@. Please go back and try again!", self.endAddress];
                              [self alertUserToErrorWithMessage:message];
                          } else {
                              NSLog(@"In end geocode completion handler");
                              self.endLocation = ((CLPlacemark *)placemarks[0]).location;
                              [self addMarkerAtLocation:self.endLocation withTitle:@"End"];
                              [self findStations];
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

-(void) configureNavigationBar {
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:35.0/255.0 green:35.0/255.0 blue:35.0/255.0 alpha: .9f];
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.leftBarButtonItem = nil;
}

-(void) configureBarHolderView {
    NSLog(@"configure bar holder view called");
    CAGradientLayer * gradient = [CAGradientLayer layer];
    
    gradient.frame = CGRectMake(0, 0, 320, 74); // hardcoded because of table view header settings
    
    NSLog(@"gradient.bounds = (%f, %f, %f, %f)", gradient.frame.origin.x, gradient.frame.origin.y, gradient.frame.size.width, gradient.frame.size.height);
    gradient.colors =  @[(id)[[UIColor colorWithRed: 230.0/255.0 green: 230.0/255.0 blue: 230.0/255.0 alpha: 1.0f] CGColor],
                         (id)[[UIColor colorWithRed:214.0/255.0 green:214.0/255.0 blue:214.0/255.0 alpha:1.0f] CGColor]];
    [self.barHolderView.layer insertSublayer:gradient atIndex:0];
    
    // 214
    
}
- (void)loadMap
{
    NSLog(@"Loading map view");
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:41.8739580629 longitude:-87.6277394859 zoom:12]; // Chicago (zoomed out)
    mapView_ = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
    mapView_.myLocationEnabled = YES;
    
    [self.view insertSubview:mapView_ atIndex:0];
}

-(void) configureLocationManager{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
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

- (void)alertUserToErrorWithMessage:(NSString *)message
{
    if (!message) message = @"Sorry! We could not find your location.";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Geocoding Error" message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
    [alert show];
}

#pragma mark - GoogleBikeRouteDelegate functions

-(void) routeWithPolyline: (GMSPolyline *) polyline{
    polyline.map = mapView_;
    
    if (++polylineCount == 3) {
        self.navigationItem.leftBarButtonItem = self.listBarButtonItem;
        self.navigationItem.rightBarButtonItem = nil;
    }
    
}


-(void) directionsFromServer: (NSDictionary *) directionsDictionary{
   
    NSArray * routesArray = directionsDictionary[@"routes"];
    
    if (routesArray.count){
        NSDictionary * routesDictionary = routesArray[0];
        NSDictionary * legsDictionary = routesDictionary[@"legs"][0];
        [self.directionsArray addObject:legsDictionary];
    }
    
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

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (self.startLocationField.editing) self.startLocationField.text = cell.textLabel.text;
    if (self.endLocationField.editing) self.endLocationField.text = cell.textLabel.text;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark - UITableViewDataSourceDelegate Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if ([self.displayedData count] < 4)
        return 4;
    else
        return [self.displayedData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"enterLocationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UIImageView * backGroundView = [[UIImageView alloc] initWithFrame:cell.frame];
    backGroundView.backgroundColor = [UIColor blackColor];
    backGroundView.alpha = .6f;
    cell.backgroundView = backGroundView;
    
    if (indexPath.row < [self.displayedData count]){
        CLPlacemark * placemark = (CLPlacemark *)self.displayedData[indexPath.row];
        cell.textLabel.text = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
        cell.userInteractionEnabled = YES;
    } else {
        cell.textLabel.text = @"";
        cell.userInteractionEnabled = NO;
    }
    
    
    return cell;
}

#pragma mark - CLLocationManagerDelegate

-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    self.locationManager = manager;
    
}

-(void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
    if (error.code == kCLErrorDenied)
        [manager stopUpdatingLocation];
    
}

#pragma mark - actions

- (IBAction)startGoing:(id)sender {
    
    if (self.startLocationField.text.length > 0 && self.endLocationField.text.length > 0){
        self.enterInstructionsView.hidden = YES;
        [self.view endEditing:YES];
        NSLog(@"start address: %@", self.startLocationField.text);
        self.startAddress = self.startLocationField.text;
        
        NSLog(@"end address: %@", self.endLocationField.text);
        self.endAddress = self.endLocationField.text;
        [self geocodeStartAddress];
        
    } 
}


#pragma mark - UITextField Delegate 

-(void) textFieldDidBeginEditing:(UITextField *)textField{
    
    if (textField.text.length > 0) [self geocodeAddressStringToDisplay:textField.text];
    
    if (textField.tag == 2 && self.startLocationField.text.length == 0){
        self.startLocationField.text = @"Current Location";
        self.startLocationField.textColor = [UIColor blueColor];
    }
    
    self.enterInstructionsView.hidden = NO;

    
}


-(void) textFieldDidEndEditing:(UITextField *)textField{
    if (textField.text.length == 0){
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{

    [self geocodeAddressStringToDisplay:textField.text];
    
    if (textField.tag == 1 && self.startLocationField.textColor != [UIColor blackColor]) self.startLocationField.textColor = [UIColor blackColor];
    
    NSLog(@"replacement string == %@, range.location == %i, range.length == %i", string, range.location, range.length);
    if (self.startLocationField.text.length > 0 && self.endLocationField.text.length > 0) self.navigationItem.rightBarButtonItem = self.goBarButtonItem;
    
    if (textField.tag == 2 && [string isEqualToString:@""] && range.location == 0 && range.length == textField.text.length) self.navigationItem.rightBarButtonItem = nil;
    
    
    return YES;
}

-(BOOL) textFieldShouldClear:(UITextField *)textField{
    
    if (textField.tag == 2) self.navigationItem.rightBarButtonItem = nil;
    
    return YES;
}
#pragma mark - UITapGestureRecognizer delegate


- (IBAction)dismiss:(id)sender {
    [self.view endEditing:YES];
    self.enterInstructionsView.hidden = YES;
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




@end
