#import "KSPromise.h"
#import "KSDeferred.h"

using namespace Cedar::Matchers;

SPEC_BEGIN(KSDeferredDeprecatedSpec)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

describe(@"KSDeferred", ^{
    __block KSPromise *promise;
    __block KSDeferred *deferred;
    
    beforeEach(^{
        deferred = [KSDeferred defer];
        promise = deferred.promise;
    });
    
    it(@"should be created", ^{
        deferred should_not be_nil;
    });
    
    it(@"should have a promise", ^{
        promise should_not be_nil;
    });
    
    describe(@"when setting a success callback", ^{
        __block BOOL called;
        __block NSString *value;
        
        beforeEach(^{
            called = NO;
            value = nil;
            [promise whenResolved:^(KSPromise *d) {
                called = YES;
                value = d.value;
            }];
        });
        
        it(@"should call the success callback when the promise gets a value", ^{
            [deferred resolveWithValue:@"SUCCESS"];
            called should be_truthy;
            value should equal(@"SUCCESS");
        });
        
        it(@"should not call the success callback when deferred is cancelled", ^{
            [promise cancel];
            [deferred resolveWithValue:@"SUCCESS"];
            called should_not be_truthy;
            value should_not equal(@"SUCCESS");
        });
        
        describe(@"when adding an additional success callback", ^{
            __block BOOL called2;
            __block NSString *value2;
            
            beforeEach(^{
                called2 = NO;
                value2 = nil;
                [promise whenResolved:^(KSPromise *d) {
                    called2 = YES;
                    value2 = d.value;
                }];
                [deferred resolveWithValue:@"SUCCESS"];
            });
            
            it(@"should call the original success callback when the promise gets a value", ^{
                called should be_truthy;
                value should equal(@"SUCCESS");
            });
            
            it(@"should call the additional success callback when the promise gets a value", ^{
                called2 should be_truthy;
                value2 should equal(@"SUCCESS");
            });
        });
    });
    
    describe(@"when adding a success callback after a success value has been set", ^{
        __block BOOL called = NO;
        __block NSString *value = nil;
        
        it(@"should call the success callback when the promise gets a value", ^{
            called should_not be_truthy;
            value should_not equal(@"SUCCESS");
            
            [deferred resolveWithValue:@"SUCCESS"];
            
            [promise whenResolved:^(KSPromise *d) {
                called = YES;
                value = d.value;
            }];
            called should be_truthy;
            value should equal(@"SUCCESS");
        });
    });
    
    describe(@"when setting an error callback", ^{
        __block BOOL called = NO;
        __block NSError *error = nil;
        
        beforeEach(^{
            called = NO;
            error = nil;
            
            [promise whenRejected:^(KSPromise *p) {
                error = p.error;
                called = YES;
            }];
        });
        
        it(@"should call the error callback when the promise gets an error", ^{
            [deferred rejectWithError:[NSError errorWithDomain:@"FAIL" code:123 userInfo:nil]];
            called should be_truthy;
            error.domain should equal(@"FAIL");
        });
        
        it(@"should not call the callback after its cancelled", ^{
            [promise cancel];
            [deferred rejectWithError:[NSError errorWithDomain:@"FAIL" code:123 userInfo:nil]];
            called should_not be_truthy;
            error.domain should_not equal(@"FAIL");
        });
        
        describe(@"when adding an additional error callback", ^{
            __block BOOL called2 = NO;
            __block NSError *error2 = nil;
            
            beforeEach(^{
                [promise whenRejected:^(KSPromise *p) {
                    error2 = p.error;
                    called2 = YES;
                }];
                
                [deferred rejectWithError:[NSError errorWithDomain:@"FAIL" code:123 userInfo:nil]];
            });
            
            it(@"should call the error callback when the promise gets an error", ^{
                called should be_truthy;
                error.domain should equal(@"FAIL");
            });
            
            it(@"should call the error callback when the promise gets an error", ^{
                called2 should be_truthy;
                error2.domain should equal(@"FAIL");
            });
        });
    });
    
    describe(@"when setting a complete callback", ^{
        __block BOOL called = NO;
        __block NSString *value = nil;
        __block NSError *error = nil;
        
        beforeEach(^{
            [promise whenFulfilled:^(KSPromise *p) {
                called = YES;
                value = p.value;
                error = p.error;
            }];
        });
        
        it(@"should call the complete callback when the promise gets a value", ^{
            [deferred resolveWithValue:@"SUCCESS"];
            called should be_truthy;
            value should equal(@"SUCCESS");
            error should be_nil;
        });
        
        it(@"should call the complete callback when the promise gets an error", ^{
            [deferred rejectWithError:[NSError errorWithDomain:@"FAIL" code:123 userInfo:nil]];
            called should be_truthy;
            value should be_nil;
            error.domain should equal(@"FAIL");
        });
        
        describe(@"when adding an additional complete callback", ^{
            __block BOOL called2 = NO;
            __block NSString *value2 = nil;
            __block NSError *error2 = nil;
            
            beforeEach(^{
                [promise whenFulfilled:^(KSPromise *p) {
                    called2 = YES;
                    value2 = p.value;
                    error2 = p.error;
                }];
            });
            
            it(@"should call both callback on success", ^{
                [deferred resolveWithValue:@"SUCCESS"];
                called should be_truthy;
                value should equal(@"SUCCESS");
                error should be_nil;
                called2 should be_truthy;
                value2 should equal(@"SUCCESS");
                error2 should be_nil;
            });
            
            it(@"should call both callback on error", ^{
                [deferred rejectWithError:[NSError errorWithDomain:@"FAIL" code:123 userInfo:nil]];
                called should be_truthy;
                value should be_nil;
                error.domain should equal(@"FAIL");
                called2 should be_truthy;
                value2 should be_nil;
                error2.domain should equal(@"FAIL");
            });
        });
    });
});

#pragma clang diagnostic pop

SPEC_END
