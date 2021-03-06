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

@interface DivvyMapViewController ()
<BGLDivvyDataAccessDelegate, GoogleBikeRouteDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate>
{
    NSInteger polylineCount;
    BOOL movedTextFieldsLeft;
    CGPoint originalTextFieldViewCenter;
    CGPoint originalMapViewCenter;
    CGPoint originalListToggleCenter;
    CGPoint originalPanTouchMapViewCenter;
    CGPoint originalShowAndClearButtonCenter;
    BOOL shouldClearPinsOnButtonPress;
}

// grabbing global location data properties
@property (strong, nonatomic) BGLDivvyDataAccess * dataAccess;
@property (strong, nonatomic) CLLocation * currentLocation;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) CLRegion *chicagoRegion;
@property (strong, nonatomic) CLLocationManager * locationManager;

// start location end location properties
@property (strong, nonatomic) NSString *startAddress;
@property (strong, nonatomic) NSString *endAddress;
@property (strong, nonatomic) CLLocation *startLocation;
@property (strong, nonatomic) CLLocation *endLocation;
@property (strong, nonatomic) IBOutlet UITextField *startLocationField;
@property (strong, nonatomic) IBOutlet UITextField *endLocationField;
@property (strong, nonatomic) BGLStationObject * startStation;
@property (strong, nonatomic) BGLStationObject * endStation;

// properties that are used to store and display data about directions
@property (strong, nonatomic) NSArray * displayedData; // this holds suggested directions to display in the enterInstructionsView
@property (strong,nonatomic) NSMutableArray * directionsArray; // this holds the direction data returned from google maps to be displayed in the UITableView on the next screen
@property (strong, nonatomic) IBOutlet UITableView *addressOptionsTableView;

// buttons
@property (strong, nonatomic) IBOutlet UIView *listToggle;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *showAndClearButton;

// views
@property (strong, nonatomic) IBOutlet UIView *barHolderView;
@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;


@end

@implementation DivvyMapViewController {
    GMSMapView *mapView_;
}


#pragma mark - --Views--
#pragma mark - View Life Cycle Implementation
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configure];
}

-(void)viewDidAppear:(BOOL)animated{
    [self configureOriginalCenters];
}

#pragma mark - View Configuration
-(void)configure
{
    //[self configureBarHolderView];
    //[self configureNavigationBar];
    [self configureLocationManager];
    [self configureMap];
    [self configureContainerView];
    [self configureTableView];
    [self configureTextFields];
    [self configureListButton];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [self.dataAccess fillStationDataASynchronously];
}

-(void) configureLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
}

-(void)configureMap
{
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:41.8739580629 longitude:-87.6277394859 zoom:12]; // Chicago (zoomed out)
    mapView_ = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
    mapView_.myLocationEnabled = YES;
    [self.view insertSubview:mapView_ atIndex:0];
}

// to ensure it is at the bottom of stack use after mapView is drawn
-(void)configureContainerView
{
    [self.view insertSubview:self.containerView belowSubview:mapView_];
}

-(void) configureTableView
{
    self.addressOptionsTableView.backgroundColor = [UIColor clearColor];
}

-(void)configureTextFields
{
    [self setLeftPaddingForTextField:self.startLocationField];
    [self setLeftPaddingForTextField:self.endLocationField];
}

-(void)configureListButton
{
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.delegate = self;
    [self.listToggle addGestureRecognizer:pan];
}

-(void)configureOriginalCenters
{
    originalListToggleCenter = self.listToggle.center;
    originalMapViewCenter = mapView_.center;
    originalTextFieldViewCenter = self.barHolderView.center;
    originalShowAndClearButtonCenter = self.showAndClearButton.center;
}

#pragma mark - Configuration Utilities
-(void)setLeftPaddingForTextField:(UITextField *) textField
{
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    textField.leftView = paddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
}

#pragma mark - --Mapping--
#pragma mark - Geocoding and routing sequence


/* read these three functions from top to bottom, start address leads to end address, which then draws the stations */
- (void)geocodeStartAddress
{
    [self moveFieldsRight];
    [self.geocoder geocodeAddressString:self.startAddress
                               inRegion:self.chicagoRegion
                      completionHandler:^(NSArray *placemarks, NSError *error) {
                          self.startLocation = ((CLPlacemark *)placemarks[0]).location;
                          if (error) {
                              NSLog(@"Error in geocoder: %@", error);
                              self.startLocation = self.locationManager.location;
                              [self geocodeEndAddress];
                          } else{
                              [self geocodeEndAddress];
                          }
                      }];
    
}

static NSString * kServerErrorMessage = @"Couldn't get directions from server, make sure you entered the address correctly.";

- (void)geocodeEndAddress
{
    [self.geocoder geocodeAddressString:self.endAddress
                               inRegion:self.chicagoRegion
                      completionHandler:^(NSArray *placemarks, NSError *error) {
                          self.endLocation = ((CLPlacemark *)placemarks[0]).location;
                          if (error) {
                              NSLog(@"Error in geocode end address: %@", error);
                              UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Try again" message: kServerErrorMessage delegate:self cancelButtonTitle:@"Will do!" otherButtonTitles: nil];
                              [alert show];
                          } else {
                              [self clearMapFindStationsAndRedrawMarkers];
                          }
                      }];
}

- (void)clearMapFindStationsAndRedrawMarkers //AndHandleRouteDrawingInDelegate
{
    [self clearMapAndRelatedData];
    [self setButtonToShow];
    BGLStationObject *pickupBikeStation = [self.dataAccess grabNearestStationTo:self.startLocation withOption:kNearestStationWithBike];
    BGLStationObject *dropoffBikeStation = [self.dataAccess grabNearestStationTo:self.endLocation withOption:kNearestStationOpen];
    
    if (!pickupBikeStation || !dropoffBikeStation) return;
    
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
    
    self.startStation = pickupBikeStation;
    self.endStation = dropoffBikeStation;
    
    [self addMarkerForStation:pickupBikeStation];
    [self addMarkerForStation:dropoffBikeStation];
    [self addMarkerAtLocation:self.startLocation withTitle:@"Start"];
    [self addMarkerAtLocation:self.endLocation withTitle:@"End"];
    
}

#pragma mark - Google Maps Utilities

-(void) clearMapAndRelatedData
{
    polylineCount = 0;
    [mapView_ clear];
    [self.directionsArray removeAllObjects];
}

// This method is used to display geocoding in real time as they enter values
-(void) geocodeAddressStringToDisplay: (NSString *) addressString
{
    // Suggests
    self.displayedData = [[NSArray alloc] init]; // create new array
    [self.geocoder geocodeAddressString:addressString inRegion:self.chicagoRegion completionHandler:^(NSArray *placemarks, NSError *error){
        
        // Filter placemarks because the above method doesn't automatically do that :(
        NSMutableArray *filteredPlacemarks = [[NSMutableArray alloc] init];
        for (CLPlacemark *placemark in placemarks)
        {
            if ([self.chicagoRegion containsCoordinate:placemark.location.coordinate])
            {
                [filteredPlacemarks addObject:placemark];
            }
        }
        self.displayedData = [filteredPlacemarks copy];
        
        [self.addressOptionsTableView reloadData];
        if (error) {
            NSLog(@"Error in geocoder: %@", error);
        }
    }];
}

// Adds a Google Maps marker at a station
- (void)addMarkerForStation:(BGLStationObject *)station
{
    GMSMarker *marker = [[GMSMarker alloc] init];
    CLLocationDegrees latitude = station.latitude;
    CLLocationDegrees longitude = station.longitude;
    marker.position = CLLocationCoordinate2DMake(latitude, longitude);
    marker.title = station.stationName;
    UIColor *divvyColor = [[UIColor alloc] initWithRed:(61./255) green:(183./255) blue:(228/255.) alpha:1];
    marker.icon = [GMSMarker markerImageWithColor:divvyColor];
    marker.snippet = [NSString stringWithFormat:@"Available Bikes: %d\rAvailable Docks: %d",
                      station.availableBikes, station.availableDocks];
    marker.map = mapView_;
}

//- (NSString *)getMarkerTitleForStation:(BGLStationObject *)station
//{
//    NSString *title = [NSString stringWithFormat:@"%@\rAvailable Bikes: %d\rAvailable Docks:%d",
//                       station.stationName, station.availableBikes, station.availableDocks];
//    return title;
//}

- (void)addMarkerAtLocation:(CLLocation *)location withTitle:(NSString *)title
{
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = location.coordinate;
    marker.title = title;
    marker.icon = [GMSMarker markerImageWithColor:[UIColor blackColor]];
    marker.map = mapView_;
}

-(void) showAllDivvyStations
{
    for (BGLStationObject * station in self.dataAccess.stationList)
        [self addMarkerForStation:station];
}

-(void) clearAllDivvyStationsNotRouted
{
    for (GMSMarker * station in mapView_.markers) station.map = nil;
    if (self.startStation && self.endStation && self.startLocation && self.endLocation){
        [self addMarkerForStation:self.startStation];
        [self addMarkerForStation:self.endStation];
        [self addMarkerAtLocation:self.startLocation withTitle:@"Start"];
        [self addMarkerAtLocation:self.endLocation withTitle:@"End"];
    }
}

#pragma mark - GoogleBikeRouteDelegate implementation

-(void) startingServerRequest
{
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
}

-(void) routeWithPolyline: (GMSPolyline *) polyline
{
    polyline.map = mapView_;
    if (++polylineCount == 3){
        self.listToggle.hidden = NO;
        [self.activityIndicator stopAnimating];
    }
}

static NSString * kNoDirectionsReturnedAlertMessage = @"There was an error finding part of your route, make sure you entered the address correctly and try again.";

-(void) directionsFromServer: (NSDictionary *) directionsDictionary
{
    NSArray * routesArray = directionsDictionary[@"routes"];
    if (routesArray.count){
        NSDictionary * routesDictionary = routesArray[0];
        NSDictionary * legsDictionary = routesDictionary[@"legs"][0];
        [self.directionsArray addObject:legsDictionary];
    } else {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Where?" message: kNoDirectionsReturnedAlertMessage delegate:self cancelButtonTitle:@"I'll try again." otherButtonTitles: nil];
        [alert show];
    }
}

#pragma mark - CLLocationManagerDelegate implementation
-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.locationManager = manager;
}

-(void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (error.code == kCLErrorDenied) [manager stopUpdatingLocation];
}

#pragma mark - --UITableViewController methods--
#pragma mark - UITableViewDelegate Functions
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    UITextView * textView = (UITextView*)[cell viewWithTag:1];
    if (self.startLocationField.editing) self.startLocationField.text = textView.text;
    if (self.endLocationField.editing) self.endLocationField.text = textView.text;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSourceDelegate Functions
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    if ([self.displayedData count] < 5)
        return 5;
    else
        return [self.displayedData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"enterLocationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.userInteractionEnabled = YES;
    UITextView * addressLabel = [self enterLocationCellTextView:cell];
    addressLabel.text = @"";
    cell.backgroundView = [self blackTransparentBackgroundWithFrame:cell.frame];
    
    if (indexPath.row < [self.displayedData count]){
        CLPlacemark * placemark = (CLPlacemark *)self.displayedData[indexPath.row];
        addressLabel.text = NSLocalizedString(ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO), nil);
        cell.userInteractionEnabled = YES;
    } else {
        cell.textLabel.text = @"";
        cell.userInteractionEnabled = NO;
    }
    
    return cell;
}

#pragma mark - UITableViewDataSourceDelegate Utilities
-(UITextView *)enterLocationCellTextView:(UITableViewCell *)cell 
{
    
    return (UITextView*)[cell viewWithTag:1];
}

-(UIImageView *)blackTransparentBackgroundWithFrame:(CGRect)frame
{
    UIImageView * backGroundView = [[UIImageView alloc] initWithFrame:frame];
    backGroundView.backgroundColor = [UIColor blackColor];
    backGroundView.alpha = .6f;
    return backGroundView;
}

#pragma mark - --User Interactions: UITextfields, Keyboard, and UIButtons--
#pragma mark - UITextFieldDelegate Utilities
-(void) makeStartFieldCurrentLocation
{
    self.startLocationField.text = @"Current Location";
    self.startLocationField.textColor = [UIColor blueColor];
}

-(CGRect) resizeRectWidthBy:(CGFloat) amount forView:(UIView *) view
{
    CGRect holderRect = view.frame;
    holderRect.size.width += amount;
    return holderRect;
}

-(void) resizeLocationFieldsByAmount:(CGFloat) amount andSetCancelHidden:(BOOL) hide
{
    /* the if statements make sure it becomes hidden at the right time, before or after the animation */
    if (hide) self.cancelButton.hidden = hide;
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.startLocationField.frame = [self resizeRectWidthBy:amount forView:self.startLocationField];
                         self.endLocationField.frame = [self resizeRectWidthBy:amount forView:self.endLocationField];
                     } completion:^(BOOL finished){
                         if (!hide) self.cancelButton.hidden = hide;
                     }];
}

-(void)moveFieldsLeft
{
    [self resizeLocationFieldsByAmount:-75.0 andSetCancelHidden:NO];
    movedTextFieldsLeft = YES;
}

-(void)moveFieldsRight
{
    [self resizeLocationFieldsByAmount:75.0 andSetCancelHidden:YES];
    movedTextFieldsLeft = NO;
}

#pragma mark - UITextField Delegate
-(void) textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField.text.length > 0) [self geocodeAddressStringToDisplay:textField.text];
    if (!movedTextFieldsLeft) [self moveFieldsLeft];
    
}

-(void) textFieldDidEndEditing:(UITextField *)textField
{
    if ((textField.text.length == 0 || [textField.text.lowercaseString isEqualToString:@"current location"]) && textField.tag == 1) {
        [self makeStartFieldCurrentLocation];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self geocodeAddressStringToDisplay:textField.text];
    if (textField.tag == 1 && self.startLocationField.textColor != [UIColor blackColor]) self.startLocationField.textColor = [UIColor blackColor];
    return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if (self.startLocationField.text.length > 0 && self.endLocationField.text.length > 0){
        self.addressOptionsTableView.hidden = YES;
        [self.view endEditing:YES];
        self.startAddress = self.startLocationField.text;
        self.endAddress = self.endLocationField.text;
        [self geocodeStartAddress];
    }
    return YES;
}

#pragma mark - NSNotification Handling

-(void)keyboardDidShow
{
    self.addressOptionsTableView.hidden = NO;
}

#pragma mark - StoryBoard Button IBActions Handling

- (IBAction)showPressed:(id)sender
{
    if (!shouldClearPinsOnButtonPress){
        [self showAllDivvyStations];
        [self setButtonToClear];
    } else if (shouldClearPinsOnButtonPress){
        [self clearAllDivvyStationsNotRouted];
        [self setButtonToShow];
    }
}

- (IBAction)cancelPressed:(id)sender
{
    [self.view endEditing:YES];
    self.addressOptionsTableView.hidden = YES;
    [self resizeLocationFieldsByAmount:75.0 andSetCancelHidden:YES];
    movedTextFieldsLeft = NO;
}


#pragma mark - IBAction Utilities

-(void) setButtonToClear
{
    shouldClearPinsOnButtonPress = YES;
    [self.showAndClearButton setTitle:@"Clear" forState:UIControlStateNormal];
}

-(void) setButtonToShow
{
    shouldClearPinsOnButtonPress = NO;
    [self.showAndClearButton setTitle:@"Show" forState:UIControlStateNormal];
}

#pragma mark - --Transitions--
#pragma mark - UIGestureRecognizerDelegate

-(void)handlePan:(UIPanGestureRecognizer *) recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan){
        originalPanTouchMapViewCenter = mapView_.center;
        if (originalPanTouchMapViewCenter.x > 0) [self presentDirections];
        self.containerView.hidden = NO;
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged){
        CGPoint touchDown = [recognizer locationInView:self.view];
        [self moveViewByTranslationDerivedFromTouch:touchDown];
    }
    
    // we have to store the original map view touch so that we know if it was on or off screen originally, and thus which direction we should animate in
    if (recognizer.state == UIGestureRecognizerStateEnded){
        CGRect screenSize = [[UIScreen mainScreen] bounds];
        CGFloat screenSizeWidth = screenSize.size.width;
        if (mapView_.center.x < screenSizeWidth * .5 && originalPanTouchMapViewCenter.x > 0){
            [self presentDirections];
            [UIView animateWithDuration:.25 animations:^{[self moveCoverViewOffScreen];}];
        }
        if (mapView_.center.x >= -1 * screenSizeWidth * .5 && originalPanTouchMapViewCenter.x < 0){
            [UIView animateWithDuration:.25 animations:^{ [self moveCoverViewOnScreen]; } completion:^(BOOL finished){ self.containerView.hidden = YES; }];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate Utilities
-(void)presentDirections
{
    for (UIViewController * viewController in self.childViewControllers){
        if ([viewController class] == [DivvyDirectionViewController class]){
            DivvyDirectionViewController * directionController = (DivvyDirectionViewController*) viewController;
            directionController.directions = self.directionsArray;
            [directionController loadTableViewData];
        }
    }
}

-(void)moveCoverViewOnScreen
{
    mapView_.center = originalMapViewCenter;
    self.listToggle.center = originalListToggleCenter;
    self.barHolderView.center = originalTextFieldViewCenter;
    self.showAndClearButton.center = originalShowAndClearButtonCenter;
}

-(void)moveCoverViewOffScreen
{
    mapView_.center = CGPointMake(originalMapViewCenter.x - 320, originalMapViewCenter.y);
    self.barHolderView.center = CGPointMake(originalTextFieldViewCenter.x - 320, originalTextFieldViewCenter.y);
    self.listToggle.center = CGPointMake(originalListToggleCenter.x - 302, originalListToggleCenter.y);
    self.showAndClearButton.center = CGPointMake(originalShowAndClearButtonCenter.x - 320, originalShowAndClearButtonCenter.y);
}

-(void)moveViewByTranslationDerivedFromTouch:(CGPoint) point
{
    CGFloat translation = self.view.frame.size.width - point.x;
    mapView_.center = [self newCenterFromOriginalCenter:originalMapViewCenter andTranslation:translation];
    self.listToggle.center = [self newCenterFromOriginalCenter:originalListToggleCenter andTranslation:translation];
    self.barHolderView.center = [self newCenterFromOriginalCenter:originalTextFieldViewCenter andTranslation:translation];
    self.showAndClearButton.center = [self newCenterFromOriginalCenter:originalShowAndClearButtonCenter andTranslation:translation];
}

-(CGPoint) newCenterFromOriginalCenter:(CGPoint) originalCenter andTranslation:(CGFloat) translation
{
    CGPoint newCenter = originalCenter;
    newCenter.x -= translation;
    return newCenter;
}

#pragma mark - --Additional Necessities--
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

#define CHICAGO_RADIUS 100000
- (CLRegion *)chicagoRegion
{
    if (!_chicagoRegion) {
        CLLocationCoordinate2D chicago = CLLocationCoordinate2DMake(41.8500, -87.6500);
        _chicagoRegion = [[CLRegion alloc] initCircularRegionWithCenter:chicago radius:CHICAGO_RADIUS identifier:@"Chicago"];
    }
    return _chicagoRegion;
}

-(NSMutableArray *) directionsArray
{
    if (!_directionsArray){
        _directionsArray = [[NSMutableArray alloc] init];
    }
    return _directionsArray;
}

-(BGLDivvyDataAccess *) dataAccess
{
    if (!_dataAccess){
        _dataAccess = [[BGLDivvyDataAccess alloc] init];
        _dataAccess.delegate = self;
        _dataAccess.autoRefresh = YES;
    }
    return _dataAccess;
}

@end
