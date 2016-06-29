#import <Cedar/Cedar.h>
#import "KSPromise.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(KSPromiseSpec)

describe(@"KSPromise", ^{

    __block KSPromise<NSString *> *promise;

    describe(@"constructors", ^{
        describe(@"+resolve:", ^{
            it(@"should create a resolved promise with the argument", ^{
                KSPromise<NSString *> *promise = [KSPromise resolve:@"A"];

                promise.fulfilled should equal(YES);
                promise.value should equal(@"A");
            });
        });

        describe(@"+reject:", ^{
            it(@"should create a rejected promise with the argument", ^{
                NSError *error = [NSError errorWithDomain:@"ERROR" code:0 userInfo:nil];
                KSPromise<NSString *> *promise = [KSPromise reject:error];

                promise.rejected should equal(YES);
                promise.error should equal(error);
            });
        });
    });


    describe(@"then:", ^{
        describe(@"for fulfilled promises", ^{
            beforeEach(^{
                promise = [KSPromise promise:^(resolveType resolve, rejectType reject) {
                    resolve(@"A");
                }];
            });
            
            it(@"must return a new promise", ^{
                KSPromise<NSString *> *thenPromise = [promise then:^id(NSString *v) { return v; }];
                
                thenPromise should_not be_same_instance_as(promise);
            });
            
            it(@"calls the fulfillment callback", ^{
                __block BOOL done = NO;
                [promise then:^NSString*(NSString *value) {
                    value should equal(@"A");
                    done = YES;
                    return value;
                }];
                done should equal(YES);
            });
        });
        
        describe(@"for rejected promises", ^{
            __block NSError *error;

            beforeEach(^{
                error = [NSError errorWithDomain:@"Broken" code:1 userInfo:nil];
                
                promise = [KSPromise promise:^(resolveType resolve, rejectType reject) {
                    reject(error);
                }];
            });

            it(@"does not call the fulfillment callback", ^{
                __block BOOL done = NO;
                [promise then:^id(NSString *s) {
                    done = YES;
                    return s;
                }];
                done should equal(NO);
            });

            it(@"rejects the returned promise with the original error", ^{
                KSPromise *nextPromise = [promise then:^id(NSString *v) { return v; }];
                nextPromise.error should equal(error);
            });
        });

        describe(@"with nil", ^{
            it(@"has a nil value", ^{
                KSPromise *promise = [KSPromise resolve:nil];

                promise.fulfilled should equal(YES);
                promise.value should be_nil;
            });
        });
    });

    describe(@"error:", ^{
        describe(@"for fulfilled promises", ^{
            beforeEach(^{
                promise = [KSPromise promise:^(resolveType resolve, rejectType reject) {
                    resolve(@"A");
                }];
            });

            it(@"must return a new promise", ^{
                KSPromise<NSString *> *errorPromise = [promise error:^id(NSError *e){ return e; }];

                errorPromise should_not be_same_instance_as(promise);
            });

            it(@"does not call the error callback", ^{
                __block BOOL done = NO;
                [promise error:^id(NSError *error) {
                    done = YES;
                    return error;
                }];
                done should equal(NO);
            });

            it(@"resolves the returned promise with the original value", ^{
                KSPromise *nextPromise = [promise error:^id(NSError *e){ return e; }];
                nextPromise.value should equal(@"A");
            });
        });

        describe(@"for rejected promises", ^{
            __block NSError *expectedError;

            beforeEach(^{
                expectedError = [NSError errorWithDomain:@"Broken" code:1 userInfo:nil];

                promise = [KSPromise promise:^(resolveType resolve, rejectType reject) {
                    reject(expectedError);
                }];
            });

            it(@"calls the error callback", ^{
                __block BOOL done = NO;
                [promise error:^id(NSError *error) {
                    error should equal(expectedError);
                    done = YES;
                    return error;
                }];
                done should equal(YES);
            });
        });
    });

    describe(@"finally:", ^{
        describe(@"for fulfilled promises", ^{
            beforeEach(^{
                promise = [KSPromise promise:^(resolveType resolve, rejectType reject) {
                    resolve(@"A");
                }];
            });

            it(@"must return a new promise", ^{
                KSPromise<NSString *> *errorPromise = [promise finally:^{}];

                errorPromise should_not be_same_instance_as(promise);
            });

            it(@"calls the callback", ^{
                __block BOOL done = NO;
                [promise finally:^ {
                    done = YES;
                }];
                done should equal(YES);
            });

            it(@"resolves the returned promise with the original value", ^{
                KSPromise *nextPromise = [promise finally:^{}];
                nextPromise.value should equal(@"A");
            });
        });

        describe(@"for rejected promises", ^{
            __block NSError *expectedError;

            beforeEach(^{
                expectedError = [NSError errorWithDomain:@"Broken" code:1 userInfo:nil];

                promise = [KSPromise promise:^(resolveType resolve, rejectType reject) {
                    reject(expectedError);
                }];
            });

            it(@"calls the callback", ^{
                __block BOOL done = NO;
                [promise finally:^ {
                    done = YES;
                }];
                done should equal(YES);
            });

            it(@"rejects the returned promise with the original error", ^{
                KSPromise *nextPromise = [promise finally:^{}];
                nextPromise.error should equal(expectedError);
            });
        });
    });
});

SPEC_END
