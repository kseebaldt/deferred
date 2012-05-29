#import <Cedar/SpecHelper.h>
#import "NSURLConnection+Deferred.h"
#import <PivotalSpecHelperKit/PSHKFakeHTTPURLResponse.h>
#import <PivotalSpecHelperKit/NSURLConnection+Spec.h>

using namespace Cedar::Matchers;

SPEC_BEGIN(NSURLConnectionDeferredSpec)

describe(@"NSURLConnection+Deferred", ^{
    __block NSURLConnection *connection;
    __block KSPromise *promise;
    __block BOOL resolvedCalled;
    __block BOOL rejectedCalled;

    beforeEach(^{
        resolvedCalled = NO;
        rejectedCalled = NO;
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.example.com/test"]];
        promise = [NSURLConnection sendRequest:request];
        connection = NSURLConnection.connections.lastObject;
        
        [promise whenResolved:^(KSPromise *p) {
            resolvedCalled = YES;
        }];
        [promise whenRejected:^(KSPromise *p) {
            rejectedCalled = YES;
        }];
    });
    
    it(@"should return a promise", ^{
        promise should_not be_nil;
    });
    
    it(@"should not be resolved", ^{
        promise.isResolved should_not be_truthy;
        resolvedCalled should_not be_truthy;
    });

    it(@"should not be rejected", ^{
        promise.isRejected should_not be_truthy;
        rejectedCalled should_not be_truthy;
    });
    
    describe(@"when the connection finishes", ^{
        beforeEach(^{
            PSHKFakeHTTPURLResponse *response = [[[PSHKFakeHTTPURLResponse alloc] initWithStatusCode:200 andHeaders:nil andBody:@"BODY"] autorelease];
            [connection receiveResponse:response];
        });
        
        it(@"should be resolved", ^{
            promise.isResolved should be_truthy;
            resolvedCalled should be_truthy;
        });
        
        it(@"should set an array with reponse and data as the value", ^{
            [promise.value count] should equal(2);
            NSHTTPURLResponse *response = [promise.value objectAtIndex:0];
            response.statusCode should equal(200);
            NSData *data = [promise.value objectAtIndex:1];
            NSString *body = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            body should equal(@"BODY");
        });
    });
    
    describe(@"when the connection fails", ^{
        __block NSError *error;
        beforeEach(^{
            error = [NSError errorWithDomain:@"SomeHTTPError" code:500 userInfo:nil];
            [connection failWithError:error];
        });
        
        it(@"should be rejected", ^{
            promise.isRejected should be_truthy;
            rejectedCalled should be_truthy;
        });
        
        it(@"should have an error", ^{
            promise.error should equal(error);
        });
    });    

});

SPEC_END
