#import "KSDeferred.h"

@interface KSPromise ()
@property (strong, nonatomic) NSMutableArray *fulfilledCallbacks;
@property (strong, nonatomic) NSMutableArray *resolvedCallbacks;
@property (strong, nonatomic) NSMutableArray *rejectedCallbacks;

@property (nonatomic) BOOL resolved;
@property (nonatomic) BOOL rejected;
@property (nonatomic) BOOL cancelled;
@end

@implementation KSPromise

@synthesize fulfilledCallbacks = _fulfilledCallbacks, resolvedCallbacks = _resolvedCallbacks, rejectedCallbacks = _rejectedCallbacks;
@synthesize value = _value, error = _error;
@synthesize resolved = _resolved, rejected = _rejected;
@synthesize cancelled = _cancelled;

- (id)init {
    self = [super init];
    if (self) {
        self.fulfilledCallbacks = [NSMutableArray array];
        self.resolvedCallbacks = [NSMutableArray array];
        self.rejectedCallbacks = [NSMutableArray array];
    }
    return self;
}

- (KSPromise *)whenFulfilled:(deferredCallback)callback {
    if (self.rejected || self.resolved) {
        callback(self);
    } else {
        [self.fulfilledCallbacks addObject:[callback copy]];
    }  
    return self;
}

- (KSPromise *)whenResolved:(deferredCallback)callback {
    if (self.resolved) {
        callback(self);
    } else {
        [self.resolvedCallbacks addObject:[callback copy]];
    }
    return self;
}

- (KSPromise *)whenRejected:(deferredErrorCallback)callback {
    if (self.rejected) {
        callback(self.error);
    } else {
        [self.rejectedCallbacks addObject:[callback copy]];
    }    
    return self;
}

- (void)resolveWithValue:(id)value {
    self.value = value;
    self.resolved = YES;
    if (self.cancelled) return;
    for (deferredCallback callback in self.resolvedCallbacks) {
        callback(self);
    }
    [self fulfill];
}

- (void)rejectWithError:(NSError *)error {
    self.error = error;
    self.rejected = YES;
    if (self.cancelled) return;
    for (deferredErrorCallback callback in self.rejectedCallbacks) {
        callback(error);
    }
    [self fulfill];
}

- (void)fulfill {
    for (deferredCallback callback in self.fulfilledCallbacks) {
        callback(self);
    }
}

- (void)cancel {
    self.cancelled = YES;
}

@end
