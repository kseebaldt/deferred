#import <Cedar/SpecHelper.h>

#import "KSPromise.h"
#import "KSDeferred.h"

using namespace Cedar::Matchers;

SPEC_BEGIN(KSDeferredSpec)

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

    describe(@"joining", ^ {
        __block KSPromise *promise2;
        __block KSDeferred *deferred2;
        __block KSPromise *joinedPromise;
        __block BOOL resolveCalled;
        __block BOOL rejectCalled;

        beforeEach(^{
            deferred2 = [KSDeferred defer];
            promise2 = deferred2.promise;
            joinedPromise = [KSPromise join:[NSArray arrayWithObjects:promise, promise2, nil]];

            resolveCalled = NO;
            [joinedPromise whenResolved:^(KSPromise *p) {
                resolveCalled = YES;
            }];

            rejectCalled = NO;
            [joinedPromise whenRejected:^(KSPromise *p) {
                rejectCalled = YES;
            }];
        });

        describe(@"when the first promise is resolved", ^{
            beforeEach(^{
                [deferred resolveWithValue:@"SUCCESS1"];
            });

            it(@"should not resolve the joined promise", ^{
                resolveCalled should_not be_truthy;
                rejectCalled should_not be_truthy;
            });

            describe(@"when both promises are resolved", ^{
                beforeEach(^{
                    [deferred2 resolveWithValue:@"SUCCESS2"];
                });

                it(@"should call the resolved callback", ^{
                    resolveCalled should be_truthy;
                });

                it(@"should be able to read the resolved values of the joined promises", ^{
                    [joinedPromise.value objectAtIndex:0] should equal(@"SUCCESS1");
                    [joinedPromise.value objectAtIndex:1] should equal(@"SUCCESS2");
                });

            });

            describe(@"when a promise is rejected and all joined promises have been fulfilled", ^{
                beforeEach(^{
                    [deferred2 rejectWithError:[NSError errorWithDomain:@"MyError" code:123 userInfo:nil]];
                });

                it(@"should call the rejected callback", ^{
                    rejectCalled should be_truthy;
                });

                it(@"should be able to read the resolved values of the joined promises", ^{
                    joinedPromise.error.domain should equal(@"KSPromiseJoinError");
                    NSArray *errors = [joinedPromise.error.userInfo objectForKey:@"errors"];
                    errors.count should equal(1);
                    [[errors lastObject] domain] should equal(@"MyError");
                });

            });
        });

        describe(@"when the first promise is rejected", ^{
            beforeEach(^{
                [deferred2 rejectWithError:[NSError errorWithDomain:@"MyError" code:123 userInfo:nil]];
            });

            it(@"should not reject the joined promise", ^{
                resolveCalled should_not be_truthy;
                rejectCalled should_not be_truthy;
            });
        });
    });
});

SPEC_END
