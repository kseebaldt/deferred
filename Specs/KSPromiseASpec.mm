#import "KSDeferred.h"
#import "KSPromise.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

// translated from: https://github.com/promises-aplus/promises-spec

@interface SpecAssertionHandler : NSAssertionHandler
@end

@implementation SpecAssertionHandler

- (void)handleFailureInMethod:(SEL)selector
                       object:(id)object
                         file:(NSString *)fileName
                   lineNumber:(NSInteger)line
                  description:(NSString *)format, ...
{
    [NSException raise:@"Assertion failure" format:@"NSAssert Failure: Method %@ for object %@ in %@#%li", NSStringFromSelector(selector), object, fileName, (long)line];
}

@end

SPEC_BEGIN(KSPromiseASpec)

describe(@"KSPromiseA", ^{
    __block KSDeferred *deferred;
    __block KSPromise *promise;

    beforeEach(^{
        NSAssertionHandler *assertionHandler = [[SpecAssertionHandler alloc] init];
        [[[NSThread currentThread] threadDictionary] setValue:assertionHandler
                                                       forKey:NSAssertionHandlerKey];

        deferred = [KSDeferred defer];
        promise = deferred.promise;
    });

    describe(@"[Promises/A] Basic characteristics of `then`", ^{
        describe(@"for fulfilled promises", ^{
            beforeEach(^{
                [deferred resolveWithValue:@"A"];
            });

            it(@"must return a new promise", ^{
                KSPromise *thenPromise = [promise then:nil error:nil];

                thenPromise should_not be_same_instance_as(promise);
            });

            it(@"calls the fulfillment callback", ^{
                __block BOOL done = NO;
                [promise then:^id(id value) {
                    value should equal(@"A");
                    done = YES;
                    return value;
                } error:nil];
                done should equal(YES);
            });
        });

        describe(@"for rejected promises", ^{
            __block NSError *error;
            beforeEach(^{
                error = [NSError errorWithDomain:@"Promise Spec" code:1 userInfo:nil];
                [deferred rejectWithError:error];
            });

            it(@"must return a new promise", ^{
                KSPromise *thenPromise = [promise then:nil error:nil];
                thenPromise should_not be_same_instance_as(promise);
            });

            it(@"calls the rejection callback", ^{
                __block BOOL done = NO;
                [promise then:nil error:^id(NSError *e) {
                    e should equal(error);
                    done = YES;
                    return e;
                }];
                done should equal(YES);
            });
        });

        describe(@"for pending promises", ^{
            it(@"must return a new promise", ^{
                KSPromise *thenPromise = [promise then:nil error:nil];

                thenPromise should_not be_same_instance_as(promise);
            });
        });
    });

    describe(@"[Promises/A] State transitions", ^{
        it(@"cannot fulfill twice", ^{
            __block int called = 0;
            [promise then:^id(id value) {
                value should equal(@"B");
                ++called;
                return value;
            } error:nil];

            [deferred resolveWithValue:@"B"];

            ^{ [deferred resolveWithValue:@"B"]; } should raise_exception();

            called should equal(1);
        });

        it(@"cannot reject twice", ^{
            NSError *error = [NSError errorWithDomain:@"Promise Spec" code:2 userInfo:nil];

            __block int called = 0;
            [promise then:nil error:^id(NSError *e) {
                e should equal(error);
                ++called;
                return e;
            }];

            [deferred rejectWithError:error];
            ^{ [deferred rejectWithError:error]; } should raise_exception();

            called should equal(1);
        });

        it(@"cannot fulfill then reject", ^{
            NSError *error = [NSError errorWithDomain:@"Promise Spec" code:3 userInfo:nil];
            __block int called = 0;
            __block id result = nil;
            [promise then:^id(id value) {
                value should equal(@"C");
                ++called;
                result = value;
                return value;
            } error:nil];

            [deferred resolveWithValue:@"C"];
            ^{ [deferred rejectWithError:error]; } should raise_exception();

            called should equal(1);
            result should equal(@"C");
        });

        it(@"cannot reject then fulfill", ^{
            NSError *error = [NSError errorWithDomain:@"Promise Spec" code:4 userInfo:nil];
            __block int called = 0;
            __block id result = nil;
            [promise then:nil error:^NSError*(NSError *e) {
                e should equal(error);
                ++called;
                result = e;
                return e;
            }];

            [deferred rejectWithError:error];
            ^{ [deferred resolveWithValue:@"D"]; } should raise_exception();

            called should equal(1);
            result should equal(error);
        });
    });

    describe(@"[Promises/A] Chaining off of a fulfilled promise", ^{
        describe(@"when the first fulfillment callback returns a new value", ^{
            it(@"should call the second fulfillment callback with that new value", ^{
                [deferred resolveWithValue:@"A"];
                KSPromise *thenPromise = [promise then:^id(id) {
                    return @"B";
                } error:nil];

                __block BOOL done = NO;
                [thenPromise then:^id(id value) {
                    done = YES;
                    value should equal(@"B");
                    return value;
                } error:nil];
                done should equal(YES);
            });
        });

        describe(@"when the first fulfillment callback returns an error", ^{
            it(@"should call the second rejection callback with that error as the reason", ^{
                NSError *error = [NSError errorWithDomain:@"Promise Spec" code:4 userInfo:nil];
                [deferred resolveWithValue:@"A"];
                KSPromise *thenPromise = [promise then:^id(id) {
                    return error;
                } error:nil];

                __block BOOL done = NO;
                [thenPromise then:nil error:^id(NSError *e) {
                    done = YES;
                    e should equal(error);
                    return e;
                }];
                done should equal(YES);
            });
        });

        describe(@"with only a rejection callback", ^{
            it(@"should call the second fulfillment callback with the original value", ^{
                [deferred resolveWithValue:@"A"];
                KSPromise *thenPromise = [promise then:nil error:^id(NSError *e) {
                    return e;
                }];

                __block BOOL done = NO;
                [thenPromise then:^id(id value){
                    value should equal(@"A");
                    done = YES;
                    return value;
                } error:nil];
                done should equal(YES);
            });
        });
    });

    describe(@"[Promises/A] Chaining off of a rejected promise", ^{
        describe(@"when the first rejection callback returns a new value", ^{
            it(@"should call the second fulfillment callback with that new value", ^{
                NSError *error = [NSError errorWithDomain:@"Promise Spec" code:1 userInfo:nil];
                [deferred rejectWithError:error];
                KSPromise *thenPromise = [promise then:nil error:^id(NSError *e){
                    return @"A";
                }];

                __block BOOL done = NO;
                [thenPromise then:^id(id value){
                    value should equal(@"A");
                    done = YES;
                    return value;
                } error:nil];
                done should equal(YES);
            });
        });

        describe(@"when the first rejection callback throws a new reason", ^{
            it(@"should call the second rejection callback with that new reason", ^{
                NSError *error = [NSError errorWithDomain:@"Promise Spec" code:1 userInfo:nil];
                NSError *error2 = [NSError errorWithDomain:@"Promise Spec" code:2 userInfo:nil];
                [deferred rejectWithError:error];
                KSPromise *thenPromise = [promise then:nil error:^NSError*(NSError *e){
                    return error2;
                }];

                __block BOOL done = NO;
                [thenPromise then:nil error:^id(NSError *e) {
                    e should equal(error2);
                    done = YES;
                    return e;
                }];
                done should equal(YES);
            });
        });

        describe(@"when there is only a fulfillment callback", ^{
            it(@"should call the second rejection callback with the original reason", ^{
                NSError *error = [NSError errorWithDomain:@"Promise Spec" code:1 userInfo:nil];
                [deferred rejectWithError:error];
                KSPromise *thenPromise = [promise then:^id(id value){
                    return value;
                } error:nil];

                __block BOOL done = NO;
                [thenPromise then:nil error:^id(NSError *e) {
                    e should equal(error);
                    done = YES;
                    return e;
                }];
                done should equal(YES);
            });
        });
    });

    describe(@"[Promises/A] Chaining off of an eventually-fulfilled promise", ^{

        describe(@"when the first fulfillment callback returns a new value", ^{
            it(@"should call the second fulfillment callback with that new value", ^{
                KSPromise *thenPromise = [promise then:^id(id value){
                    return value;
                } error:nil];


                __block BOOL done = NO;
                [thenPromise then:^id(id value) {
                    value should equal(@"A");
                    done = YES;
                    return value;
                } error:nil];

                [deferred resolveWithValue:@"A"];
                done should equal(YES);
            });
        });

        describe(@"when the first fulfillment callback returns an error", ^{
            it(@"should call the second rejection callback with that error as the reason", ^{
                NSError *error = [NSError errorWithDomain:@"Promise Spec" code:1 userInfo:nil];
                KSPromise *thenPromise = [promise then:^id(id value){
                    return error;
                } error:nil];

                __block BOOL done = NO;
                [thenPromise then:nil error:^id(NSError *e) {
                    e should equal(error);
                    done = YES;
                    return e;
                }];
                [deferred resolveWithValue:@"A"];
                done should equal(YES);
            });
        });

        describe(@"with only a rejection callback", ^{
            it(@"should call the second fulfillment callback with the original value", ^{
                KSPromise *thenPromise = [promise then:nil error:^id(NSError *error){
                    return error;
                }];

                __block BOOL done = NO;
                [thenPromise then:^id(id value) {
                    value should equal(@"A");
                    done = YES;
                    return value;
                } error:nil];
                [deferred resolveWithValue:@"A"];
                done should equal(YES);
            });
        });
    });


    describe(@"[Promises/A] Chaining off of an eventually-rejected promise", ^{
        describe(@"when the first rejection callback returns a new value", ^{
            it(@"should call the second fulfillment callback with that new value", ^{
                KSPromise *thenPromise = [promise then:nil error:^id(NSError *error){
                    return @"A";
                }];

                __block BOOL done = NO;
                [thenPromise then:^id(id value) {
                    value should equal(@"A");
                    done = YES;
                    return value;
                } error:nil];
                [deferred rejectWithError:[NSError errorWithDomain:@"error" code:123 userInfo:nil]];
                done should equal(YES);
            });
        });

        describe(@"when the first rejection callback throws a new reason", ^{
            it(@"should call the second rejection callback with that new reason", ^{
                NSError *otherError = [NSError errorWithDomain:@"otherError" code:321 userInfo:nil];
                KSPromise *thenPromise = [promise then:nil error:^id(NSError *error){
                    return otherError;
                }];

                NSError *firstError = [NSError errorWithDomain:@"error" code:123 userInfo:nil];

                __block BOOL done = NO;
                [thenPromise then:nil error:^id(NSError *error) {
                    error should equal(otherError);
                    done = YES;
                    return error;
                }];
                [deferred rejectWithError:firstError];
                done should equal(YES);
            });
        });

        describe(@"when there is only a fulfillment callback", ^{
            it(@"should call the second rejection callback with the original reason", ^{
                KSPromise *thenPromise = [promise then:^id(id value){
                    return value;
                } error:nil];

                NSError *firstError = [NSError errorWithDomain:@"error" code:123 userInfo:nil];

                __block BOOL done = NO;
                [thenPromise then:nil error:^id(NSError *error) {
                    error should equal(firstError);
                    done = YES;
                    return error;
                }];
                [deferred rejectWithError:firstError];
                done should equal(YES);
            });
        });
    });

    describe(@"[Promises/A] Multiple handlers", ^{
        describe(@"when there are multiple fulfillment handlers for a fulfilled promise", ^{
            it(@"should call them all, in order, with the same fulfillment value", ^{
                [deferred resolveWithValue:@"A"];

                NSMutableArray *dones = [NSMutableArray array];

                // Don't let their return value *or* thrown exceptions impact each other.
                [promise then:^id(id value){
                    value should equal(@"A");
                    [dones addObject:@"1"];
                    return @"B";
                } error:nil];

                [promise then:^id(id value){
                    value should equal(@"A");
                    [dones addObject:@"2"];
                    return [NSError errorWithDomain:@"C" code:123 userInfo:nil];
                } error:nil];

                [promise then:^id(id value){
                    value should equal(@"A");
                    [dones addObject:@"3"];
                    return @"D";
                } error:nil];

                dones should equal(@[@"1", @"2", @"3"]);
            });

            it(@"should generate multiple branching chains with their own fulfillment values", ^{
                [deferred resolveWithValue:@"A"];

                NSMutableArray *dones = [NSMutableArray array];

                // Don't let their return value *or* thrown exceptions impact each other.
                KSPromise *p1 = [promise then:^id(id value){
                    value should equal(@"A");
                    [dones addObject:@"1"];
                    return @"B";
                } error:nil];

                [p1 then:^id(id value){
                    value should equal(@"B");
                    [dones addObject:@"2"];
                    return @"C";
                } error:nil];

                KSPromise *p2 = [promise then:^id(id value){
                    value should equal(@"A");
                    [dones addObject:@"3"];
                    return @"D";
                } error:nil];

                [p2 then:^id(id value){
                    value should equal(@"D");
                    [dones addObject:@"4"];
                    return @"E";
                } error:nil];

                dones should equal(@[@"1", @"2", @"3", @"4"]);
            });
        });

        describe(@"when there are multiple rejection handlers for a rejected promise", ^{
            it(@"should call them all, in order, with the same rejection reason", ^{
                NSError *error = [NSError errorWithDomain:@"A" code:123 userInfo:nil];
                [deferred rejectWithError:error];

                NSMutableArray *dones = [NSMutableArray array];

                // Don't let their return value *or* errors impact each other.
                [promise then:nil error:^id(NSError *e){
                    e should equal(error);
                    [dones addObject:@"1"];
                    return e;
                }];

                [promise then:nil error:^id(NSError *e){
                    e should equal(error);
                    [dones addObject:@"2"];
                    return @"B";
                }];

                [promise then:nil error:^id(NSError *e){
                    e should equal(error);
                    [dones addObject:@"3"];
                    return e;
                }];

                dones should equal(@[@"1", @"2", @"3"]);
            });
        });
    });

    describe(@"[Promises/A] Attaching handlers later", ^{
        describe(@"to a fulfilled promise", ^{
            it(@"should call the handler with the fulfillment value", ^{
                [deferred resolveWithValue:@"A"];

                __block BOOL done = NO;
                [promise then:^id(id value) {
                    value should equal(@"A");
                    done = YES;
                    return value;
                } error:nil];

                done should equal(YES);
            });
        });

        describe(@"to a rejected promise", ^{
            it(@"should call the rejection handler with the rejection reason", ^{
                NSError *error = [NSError errorWithDomain:@"A" code:123 userInfo:nil];
                [deferred rejectWithError:error];

                __block BOOL done = NO;
                [promise then:nil error:^id(NSError *e) {
                    e should equal(error);
                    done = YES;
                    return e;
                }];

                done should equal(YES);
            });
        });
    });

    describe(@"[Promises/A] Returning a promise", ^{
        __block KSDeferred *returnedDeferred;
        NSError *returnedPromiseError = [NSError errorWithDomain:@"Promise Spec" code:1 userInfo:nil];

        beforeEach(^{
            returnedDeferred = [KSDeferred defer];
        });

        describe(@"from a fulfillment handler", ^{
            beforeEach(^{
                [deferred resolveWithValue:@"A"];
            });

            describe(@"when the returned promise is resolved", ^{
                it(@"should call the next fulfillment handler with the returned promise's value", ^{

                    __block BOOL done = NO;
                    [[promise then:^id(id value) {
                        return returnedDeferred.promise;
                    } error:nil] then:^id(id value) {
                        value should equal(@"B");
                        done = YES;
                        return value;
                    } error:nil];

                    done should equal(NO);
                    [returnedDeferred resolveWithValue:@"B"];
                    done should equal(YES);
                });
            });

            describe(@"when the returned promise is rejected", ^{
                it(@"should call the next rejection handler with the returned promise's error", ^{
                    __block BOOL done = NO;
                    [[promise then:^id(id value) {
                        return returnedDeferred.promise;
                    } error:nil] then:nil error:^id(NSError *error) {
                        error should equal(returnedPromiseError);
                        done = YES;
                        return error;
                    }];

                    done should equal(NO);
                    [returnedDeferred rejectWithError:returnedPromiseError];
                    done should equal(YES);
                });
            });
        });

        describe(@"from a rejection handler", ^{
            beforeEach(^{
                [deferred rejectWithError:[NSError errorWithDomain:@"Promise Spec" code:2 userInfo:nil]];
            });

            describe(@"when the returned promise is resolved", ^{
                it(@"should call the next fulfillment handler with the returned promise's value", ^{
                    __block BOOL done = NO;
                    [[promise then:nil error:^id(NSError *error) {
                        return returnedDeferred.promise;
                    }] then:^id(id value) {
                        value should equal(@"B");
                        done = YES;
                        return value;
                    } error:nil];

                    done should equal(NO);
                    [returnedDeferred resolveWithValue:@"B"];
                    done should equal(YES);
                });
            });

            describe(@"when the returned promise is rejected", ^{
                it(@"should call the next rejection handler with the returned promise's error", ^{
                    __block BOOL done = NO;
                    [[promise then:nil error:^id(NSError *error) {
                        return returnedDeferred.promise;
                    }] then:nil error:^id(NSError *error) {
                        error should equal(returnedPromiseError);
                        done = YES;
                        return error;
                    }];

                    done should equal(NO);
                    [returnedDeferred rejectWithError:returnedPromiseError];
                    done should equal(YES);
                });
            });
        });
    });

});

SPEC_END
