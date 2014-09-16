#import <Cordova/CDV.h>

@interface IonicUpdate : CDVPlugin <NSURLConnectionDataDelegate>

- (void) initialize:(CDVInvokedUrlCommand *)command;

- (void) check:(CDVInvokedUrlCommand *)command;

- (void) download:(CDVInvokedUrlCommand *)command;

- (void) extract:(CDVInvokedUrlCommand *)command;

- (void) redirect:(CDVInvokedUrlCommand *)command;

- (NSDictionary *) httpRequest:(NSString *) endpoint;

- (bool) checkForUpdates;

- (void) downloadUpdate:(NSString *) download_url;

- (void) unzip;

- (void) doRedirect;

- (NSMutableArray *) getMyVersions;

- (bool) hasVersion:(NSString *) uuid;

- (void) saveVersion:(NSString *) uuid;

- (void) cleanupVersions;

- (void) removeVersions;

@end