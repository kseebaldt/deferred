#import <Cedar/SpecHelper.h>
#import "KSDeferred.h"
#import "KSPromiseA.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(KSPromiseASpec)

describe(@"KSPromiseA", ^{
    __block KSPromiseA *promise;
    
    beforeEach(^{
        promise = [[KSPromiseA alloc] init];
    });

    describe(@"[Promises/A] Basic characteristics of `then`", ^{
        describe(@"for fulfilled promises", ^{
            beforeEach(^{
                [promise resolveWithValue:@"A"];
            });
            
            it(@"must return a new promise", ^{
                KSPromiseA *thenPromise = [promise then:nil error:nil];
                
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
                [promise rejectWithError:error];
            });
            
            it(@"must return a new promise", ^{
                KSPromiseA *thenPromise = [promise then:nil error:nil];
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
                KSPromiseA *thenPromise = [promise then:nil error:nil];
                
                thenPromise should_not be_same_instance_as(promise);
            });
        });
    });
    
    describe(@"[Promises/A] State transitions", ^{
        // NOTE: Promises/A does not specify that attempts to change state twice
        // should be silently ignored, so we allow implementations to throw
        // exceptions. See resolution-races.js for more info.
        it(@"cannot fulfill twice", ^{
            __block int called = 0;
            [promise then:^id(id value) {
                value should equal(@"B");
                ++called;
                return value;
            } error:nil];
            
            [promise resolveWithValue:@"B"];
            [promise resolveWithValue:@"B"];

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
            
            [promise rejectWithError:error];
            [promise rejectWithError:error];
            
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
            } error:^NSError*(NSError *e) {
                e should equal(error);
                ++called;
                result = e;
                return e;
            }];
            
            [promise resolveWithValue:@"C"];
            [promise rejectWithError:error];
            
            called should equal(1);
            result should equal(@"C");
        });
        
        it(@"cannot reject then fulfill", ^{
            NSError *error = [NSError errorWithDomain:@"Promise Spec" code:4 userInfo:nil];
            __block int called = 0;
            __block id result = nil;
            [promise then:^id(id value) {
                value should equal(@"D");
                ++called;
                result = value;
                return value;
            } error:^NSError*(NSError *e) {
                e should equal(error);
                ++called;
                result = e;
                return e;
            }];
            
            [promise rejectWithError:error];
            [promise resolveWithValue:@"D"];
            
            called should equal(1);
            result should equal(error);
        });
    });
    
    describe(@"[Promises/A] Chaining off of a fulfilled promise", ^{
        describe(@"when the first fulfillment callback returns a new value", ^{
            it(@"should call the second fulfillment callback with that new value", ^{
                [promise resolveWithValue:@"A"];
                KSPromiseA *thenPromise = [promise then:^id(id) {
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
                [promise resolveWithValue:@"A"];
                KSPromiseA *thenPromise = [promise then:^id(id) {
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
                [promise resolveWithValue:@"A"];
                KSPromiseA *thenPromise = [promise then:nil error:^id(NSError *e) {
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
                [promise rejectWithError:error];
                KSPromiseA *thenPromise = [promise then:nil error:^id(NSError *e){
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
                [promise rejectWithError:error];
                KSPromiseA *thenPromise = [promise then:nil error:^NSError*(NSError *e){
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
                [promise rejectWithError:error];
                KSPromiseA *thenPromise = [promise then:^id(id value){
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
                KSPromiseA *thenPromise = [promise then:^id(id value){
                    return value;
                } error:nil];
                
                
                __block BOOL done = NO;
                [thenPromise then:^id(id value) {
                    value should equal(@"A");
                    done = YES;
                    return value;
                } error:nil];

                [promise resolveWithValue:@"A"];
                done should equal(YES);
            });
        });

        describe(@"when the first fulfillment callback returns an error", ^{
            it(@"should call the second rejection callback with that error as the reason", ^{                
                NSError *error = [NSError errorWithDomain:@"Promise Spec" code:1 userInfo:nil];
                KSPromiseA *thenPromise = [promise then:^id(id value){
                    return error;
                } error:nil];
                
                __block BOOL done = NO;
                [thenPromise then:^id(id value) {
                    value should equal(@"A");
                    done = YES;
                    return value;
                } error:nil];
                [promise resolveWithValue:@"A"];
                done should equal(YES);
            });
        });
        
        describe(@"with only a rejection callback", ^{
            it(@"should call the second fulfillment callback with the original value", ^{                
                KSPromiseA *thenPromise = [promise then:nil error:^id(NSError *error){
                    return error;
                }];
                
                __block BOOL done = NO;
                [thenPromise then:^id(id value) {
                    value should equal(@"A");
                    done = YES;
                    return value;
                } error:nil];
                [promise resolveWithValue:@"A"];
                done should equal(YES);
            });
        });
    });
    
   
    describe(@"[Promises/A] Chaining off of an eventually-rejected promise", ^{
        describe(@"when the first rejection callback returns a new value", ^{
            it(@"should call the second fulfillment callback with that new value", ^{                
                KSPromiseA *thenPromise = [promise then:nil error:^id(NSError *error){
                    return @"A";
                }];
                
                __block BOOL done = NO;
                [thenPromise then:^id(id value) {
                    value should equal(@"A");
                    done = YES;
                    return value;
                } error:nil];
                [promise rejectWithError:[NSError errorWithDomain:@"error" code:123 userInfo:nil]];
                done should equal(YES);
            });
        });
        
        describe(@"when the first rejection callback throws a new reason", ^{
            it(@"should call the second rejection callback with that new reason", ^{
                NSError *otherError = [NSError errorWithDomain:@"otherError" code:321 userInfo:nil];
                KSPromiseA *thenPromise = [promise then:nil error:^id(NSError *error){
                    return otherError;
                }];
                
                NSError *firstError = [NSError errorWithDomain:@"error" code:123 userInfo:nil];
                
                __block BOOL done = NO;
                [thenPromise then:nil error:^id(NSError *error) {
                    error should equal(otherError);
                    done = YES;
                    return error;
                }];
                [promise rejectWithError:firstError];
                done should equal(YES);
            });
        });
        
        describe(@"when there is only a fulfillment callback", ^{
            it(@"should call the second rejection callback with the original reason", ^{
                KSPromiseA *thenPromise = [promise then:^id(id value){
                    return value;
                } error:nil];
                
                NSError *firstError = [NSError errorWithDomain:@"error" code:123 userInfo:nil];
                
                __block BOOL done = NO;
                [thenPromise then:nil error:^id(NSError *error) {
                    error should equal(firstError);
                    done = YES;
                    return error;
                }];
                [promise rejectWithError:firstError];
                done should equal(YES);
            });
        });
    });

    describe(@"[Promises/A] Multiple handlers", ^{
        describe(@"when there are multiple fulfillment handlers for a fulfilled promise", ^{
            it(@"should call them all, in order, with the same fulfillment value", ^{
                [promise resolveWithValue:@"A"];
                
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
                [promise resolveWithValue:@"A"];
                
                NSMutableArray *dones = [NSMutableArray array];
                
                // Don't let their return value *or* thrown exceptions impact each other.
                KSPromiseA *p1 = [promise then:^id(id value){
                    value should equal(@"A");
                    [dones addObject:@"1"];
                    return @"B";
                } error:nil];
                
                [p1 then:^id(id value){
                    value should equal(@"B");
                    [dones addObject:@"2"];
                    return @"C";
                } error:nil];
                
                KSPromiseA *p2 = [promise then:^id(id value){
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
                [promise rejectWithError:error];
                
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
                [promise resolveWithValue:@"A"];

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
                [promise rejectWithError:error];
                
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

});

SPEC_END
