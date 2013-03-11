#import "KSPromiseA.h"

@interface KSPromiseCallbacks : NSObject
@property (copy, nonatomic) promiseValueCallback fulfilledCallback;
@property (copy, nonatomic) promiseErrorCallback errorCallback;
@property (strong, nonatomic) KSPromiseA *childPromise;
@end

@implementation KSPromiseCallbacks

- (id)initWithFulfilledCallback:(promiseValueCallback)fulfilledCallback errorCallback:(promiseErrorCallback)errorCallback {
    self = [super init];
    if (self) {
        self.fulfilledCallback = fulfilledCallback;
        self.errorCallback = errorCallback;
        self.childPromise = [[KSPromiseA alloc] init];
    }
    return self;
}

@end

@interface KSPromiseA ()
@property (strong, nonatomic) NSMutableArray *callbacks;

@property (strong, nonatomic) KSPromiseA *childPromise;

@property (strong, nonatomic, readwrite) id value;
@property (strong, nonatomic, readwrite) NSError *error;

@property (assign, nonatomic) BOOL fulfilled;
@property (assign, nonatomic) BOOL rejected;
@end

@implementation KSPromiseA

- (id)init {
    self = [super init];
    if (self) {
        self.callbacks = [NSMutableArray array];
    }
    return self;
}

- (KSPromiseA *)then:(promiseValueCallback)fulfilledCallback error:(promiseErrorCallback)errorCallback {
    if (self.fulfilled) {
        id newValue = self.value;
        if (fulfilledCallback) {
           newValue = fulfilledCallback(self.value);
        }
        KSPromiseA *promise = [[KSPromiseA alloc] init];
        if ([newValue isKindOfClass:[NSError class]]) {
            [promise rejectWithError:newValue];
        } else {
            [promise resolveWithValue:newValue];
        }
        return promise;
    } else if (self.rejected) {
        id nextValue = self.error;
        if (errorCallback) {
            nextValue = errorCallback(self.error);
        }
        KSPromiseA *promise = [[KSPromiseA alloc] init];
        if ([nextValue isKindOfClass:[NSError class]]) {
            [promise rejectWithError:nextValue];
        } else {
            [promise resolveWithValue:nextValue];
        }
        return promise;
    } else {
        KSPromiseCallbacks *callbacks = [[KSPromiseCallbacks alloc] initWithFulfilledCallback:fulfilledCallback errorCallback:errorCallback];
        [self.callbacks addObject:callbacks];
        return callbacks.childPromise;
    }
}

- (void)resolveWithValue:(id)value {
    if (self.completed) return;
    self.value = value;
    self.fulfilled = YES;
    for (KSPromiseCallbacks *callbacks in self.callbacks) {
        id nextValue = self.value;
        if (callbacks.fulfilledCallback) {
            callbacks.fulfilledCallback(value);
        }
        if ([nextValue isKindOfClass:[NSError class]]) {
            [callbacks.childPromise rejectWithError:nextValue];
        } else {
            [callbacks.childPromise resolveWithValue:nextValue];
        }
    }
    [self.callbacks removeAllObjects];
}

- (void)rejectWithError:(NSError *)error {
    if (self.completed) return;
    self.error = error;
    self.rejected = YES;
    for (KSPromiseCallbacks *callbacks in self.callbacks) {
        id nextValue = self.error;
        if (callbacks.errorCallback) {
            nextValue= callbacks.errorCallback(error);
        }
        if ([nextValue isKindOfClass:[NSError class]]) {
            [callbacks.childPromise rejectWithError:nextValue];
        } else {
            [callbacks.childPromise resolveWithValue:nextValue];
        }
    }
    [self.callbacks removeAllObjects];
}

- (BOOL)completed {
    return self.fulfilled || self.rejected;
}

@end
