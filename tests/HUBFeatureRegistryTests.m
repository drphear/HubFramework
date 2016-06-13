#import <XCTest/XCTest.h>

#import "HUBFeatureRegistryImplementation.h"
#import "HUBFeatureRegistration.h"
#import "HUBContentOperationFactoryMock.h"
#import "HUBViewURIPredicate.h"

@interface HUBFeatureRegistryTests : XCTestCase

@property (nonatomic, strong) HUBFeatureRegistryImplementation *registry;

@end

@implementation HUBFeatureRegistryTests

#pragma mark - XCTestCase

- (void)setUp
{
    [super setUp];
    self.registry = [HUBFeatureRegistryImplementation new];
}

#pragma mark - Tests

- (void)testConflictingIdentifiersTriggerAssert
{
    NSString * const identifier = @"identifier";
    
    NSURL * const rootViewURI = [NSURL URLWithString:@"spotify:hub:framework"];
    HUBViewURIPredicate * const viewURIPredicate = [HUBViewURIPredicate predicateWithRootViewURI:rootViewURI];
    id<HUBContentOperationFactory> const contentOperationFactory = [[HUBContentOperationFactoryMock alloc] initWithContentOperations:@[]];
    
    [self.registry registerFeatureWithIdentifier:identifier
                                viewURIPredicate:viewURIPredicate
                                           title:@"Title"
                       contentOperationFactories:@[contentOperationFactory]
                             contentReloadPolicy:nil
                      customJSONSchemaIdentifier:nil
                       componentSelectionHandler:nil];
    
    XCTAssertThrows([self.registry registerFeatureWithIdentifier:identifier
                                                viewURIPredicate:viewURIPredicate
                                                           title:@"Title"
                                       contentOperationFactories:@[contentOperationFactory]
                                             contentReloadPolicy:nil
                                      customJSONSchemaIdentifier:nil
                                       componentSelectionHandler:nil]);
}

- (void)testRegistrationPropertyAssignment
{
    NSString * const featureIdentifier = @"identifier";
    NSURL * const rootViewURI = [NSURL URLWithString:@"spotify:hub:framework"];
    HUBViewURIPredicate * const viewURIPredicate = [HUBViewURIPredicate predicateWithRootViewURI:rootViewURI];
    id<HUBContentOperationFactory> const contentOperationFactory = [[HUBContentOperationFactoryMock alloc] initWithContentOperations:@[]];
    NSString * const customJSONSchemaIdentifier = @"JSON Schema";
    
    [self.registry registerFeatureWithIdentifier:featureIdentifier
                                viewURIPredicate:viewURIPredicate
                                           title:@"Title"
                       contentOperationFactories:@[contentOperationFactory]
                             contentReloadPolicy:nil
                      customJSONSchemaIdentifier:customJSONSchemaIdentifier
                       componentSelectionHandler:nil];
    
    HUBFeatureRegistration * const registration = [self.registry featureRegistrationForViewURI:rootViewURI];
    XCTAssertEqualObjects(registration.featureIdentifier, featureIdentifier);
    XCTAssertEqualObjects(registration.featureTitle, @"Title");
    XCTAssertEqual(registration.viewURIPredicate, viewURIPredicate);
    XCTAssertEqualObjects(registration.contentOperationFactories, @[contentOperationFactory]);
    XCTAssertEqualObjects(registration.customJSONSchemaIdentifier, customJSONSchemaIdentifier);
}

- (void)testPredicateViewURIDisqualification
{
    HUBViewURIPredicate * const viewURIPredicate = [HUBViewURIPredicate predicateWithBlock:^BOOL(NSURL *evaluatedViewURI) {
        return NO;
    }];
    
    id<HUBContentOperationFactory> const contentOperationFactory = [[HUBContentOperationFactoryMock alloc] initWithContentOperations:@[]];
    
    [self.registry registerFeatureWithIdentifier:@"feature"
                                viewURIPredicate:viewURIPredicate
                                           title:@"Title"
                       contentOperationFactories:@[contentOperationFactory]
                             contentReloadPolicy:nil
                      customJSONSchemaIdentifier:nil
                       componentSelectionHandler:nil];
    
    NSURL * const viewURI = [NSURL URLWithString:@"spotify:hub:framework"];
    XCTAssertNil([self.registry featureRegistrationForViewURI:viewURI]);
}

- (void)testFeatureRegistrationOrderDeterminingViewURIEvaluationOrder
{
    HUBViewURIPredicate * const viewURIPredicate = [HUBViewURIPredicate predicateWithBlock:^BOOL(NSURL *evaluatedViewURI) {
        return YES;
    }];
    
    id<HUBContentOperationFactory> const contentOperationFactory = [[HUBContentOperationFactoryMock alloc] initWithContentOperations:@[]];
    
    [self.registry registerFeatureWithIdentifier:@"featureA"
                                viewURIPredicate:viewURIPredicate
                                           title:@"Title"
                       contentOperationFactories:@[contentOperationFactory]
                             contentReloadPolicy:nil
                      customJSONSchemaIdentifier:nil
                       componentSelectionHandler:nil];
    
    [self.registry registerFeatureWithIdentifier:@"featureB"
                                viewURIPredicate:viewURIPredicate
                                           title:@"Title"
                       contentOperationFactories:@[contentOperationFactory]
                             contentReloadPolicy:nil
                      customJSONSchemaIdentifier:nil
                       componentSelectionHandler:nil];
    
    NSURL * const viewURI = [NSURL URLWithString:@"spotify:hub:framework"];
    XCTAssertEqualObjects([self.registry featureRegistrationForViewURI:viewURI].featureIdentifier, @"featureA");
}

- (void)testUnregisteringFeature
{
    NSString * const identifier = @"Awesome feature";
    NSURL * const rootViewURI = [NSURL URLWithString:@"spotify:hub:framework"];
    HUBViewURIPredicate * const viewURIPredicate = [HUBViewURIPredicate predicateWithRootViewURI:rootViewURI];
    id<HUBContentOperationFactory> const contentOperationFactory = [[HUBContentOperationFactoryMock alloc] initWithContentOperations:@[]];
    
    [self.registry registerFeatureWithIdentifier:identifier
                                viewURIPredicate:viewURIPredicate
                                           title:@"Title"
                       contentOperationFactories:@[contentOperationFactory]
                             contentReloadPolicy:nil
                      customJSONSchemaIdentifier:nil
                       componentSelectionHandler:nil];
    
    [self.registry unregisterFeatureWithIdentifier:identifier];
    
    // The feature should now be free to be re-registered without triggering an assert
    [self.registry registerFeatureWithIdentifier:identifier
                                viewURIPredicate:viewURIPredicate
                                           title:@"Title"
                       contentOperationFactories:@[contentOperationFactory]
                             contentReloadPolicy:nil
                      customJSONSchemaIdentifier:nil
                       componentSelectionHandler:nil];
}

@end
