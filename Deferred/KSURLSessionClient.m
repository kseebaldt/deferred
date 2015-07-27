#import "KSURLSessionClient.h"
#import "KSDeferred.h"

@interface KSURLSessionClient ()
@property (strong, nonatomic, readwrite) NSURLSession *session;
@end

@implementation KSURLSessionClient

- (instancetype)init {
    return [self initWithURLSession:[NSURLSession sharedSession]];
}

- (instancetype)initWithURLSession:(NSURLSession *)session {
    self = [super init];
    if (self) {
        self.session = session;
    }
    return self;
}

- (KSPromise KS_GENERIC(KSNetworkResponse *) *)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue {
    __block KSDeferred KS_GENERIC(KSNetworkResponse *) *deferred = [KSDeferred defer];

    [[self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [queue addOperationWithBlock:^{
            if (error) {
                [deferred rejectWithError:error];
            } else {
                [deferred resolveWithValue:[KSNetworkResponse networkResponseWithURLResponse:response
                                                                                        data:data]];
            }
        }];
    }] resume];

    return deferred.promise;
}

@end
