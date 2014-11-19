#import "IonicUpdate.h"
#import <Cordova/CDV.h>
#import "UNIRest.h"
#import "SSZipArchive.h"

@interface IonicUpdate()

@property (nonatomic) NSURLConnection *connectionManager;
@property (nonatomic) NSMutableData *downloadedMutableData;
@property (nonatomic) NSURLResponse *urlResponse;

@property int progress;
@property NSString *callbackId;
@property NSString *appId;

@end

static NSOperationQueue *delegateQueue;

typedef struct JsonHttpResponse {
    __unsafe_unretained NSString *message;
    __unsafe_unretained NSDictionary *json;
} JsonHttpResponse;

@implementation IonicUpdate

- (void) initialize:(CDVInvokedUrlCommand *)command {
    CDVPluginResult* pluginResult = nil;
    
    self.appId = [command.arguments objectAtIndex:0];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) check:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSInteger redirected = [[NSUserDefaults standardUserDefaults] integerForKey:@"redirected"];
        
        if (redirected == 1) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"false"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            NSString *our_version = [[NSUserDefaults standardUserDefaults] objectForKey:@"uuid"];
                
            NSString *endpoint = [NSString stringWithFormat:@"/api/v1/app/%@/updates/check", self.appId];
                
            JsonHttpResponse result = [self httpRequest:endpoint];
            
            NSLog(@"Response: %@", result.message);
            
            if (result.json != nil && [result.json objectForKey:@"uuid"]) {
                NSString *uuid = [result.json objectForKey:@"uuid"];
                    
                // Save the "deployed" UUID so we can fetch it later
                [prefs setObject: uuid forKey: @"upstream_uuid"];
                [prefs synchronize];
                    
                NSString *updatesAvailable = ![uuid isEqualToString:our_version] ? @"true" : @"false";
                    
                NSLog(@"UUID: %@ OUR_UUID: %@", uuid, our_version);
                NSLog(@"Updates Available: %@", updatesAvailable);
                    
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:updatesAvailable];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:result.message];
            }
                
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

- (void) download:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        // Save this to a property so we can have the download progress delegate thing send
        // progress update callbacks
        self.callbackId = command.callbackId;
    
        NSString *endpoint = [NSString stringWithFormat:@"/api/v1/app/%@/updates/download", self.appId];
    
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
        NSString *upstream_uuid = [[NSUserDefaults standardUserDefaults] objectForKey:@"upstream_uuid"];
        
        NSLog(@"Upstream UUID: %@", upstream_uuid);
        
        if (upstream_uuid != nil && [self hasVersion:upstream_uuid]) {
            // Set the current version to the upstream version (we already have this version)
            [prefs setObject:upstream_uuid forKey:@"uuid"];
            [prefs synchronize];
            
            [self doRedirect];
        } else {
            JsonHttpResponse result = [self httpRequest:endpoint];
            
            NSString *download_url = [result.json objectForKey:@"download_url"];
                        
            self.downloadManager = [[DownloadManager alloc] initWithDelegate:self];
            
            NSURL *url = [NSURL URLWithString:download_url];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,@"www.zip"];
            
            NSLog(@"Queueing Download...");
            [self.downloadManager addDownloadWithFilename:filePath URL:url];
        }
    }];
}

- (void) extract:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        self.callbackId = command.callbackId;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *uuid = [[NSUserDefaults standardUserDefaults] objectForKey:@"uuid"];
        
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, @"www.zip"];
        NSString *extractPath = [NSString stringWithFormat:@"%@/%@/", documentsDirectory, uuid];
        
        NSLog(@"Path for zip file: %@", filePath);
        
        NSLog(@"Unzipping...");
        
        [SSZipArchive unzipFileAtPath:filePath toDestination:extractPath delegate:self];
        
        NSLog(@"Unzipped...");
    }];
}

- (void) redirect:(CDVInvokedUrlCommand *)command {
    CDVPluginResult* pluginResult = nil;
    
    [self doRedirect];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void) doRedirect {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger redirected = [[NSUserDefaults standardUserDefaults] integerForKey:@"redirected"];

    if (redirected == 1) {
      [prefs setInteger:0 forKey:@"redirected"];
      [prefs synchronize];
    } else {
      NSString *uuid = [[NSUserDefaults standardUserDefaults] objectForKey:@"uuid"];
      int versionCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"version_count"];

      NSString *versionString = [NSString stringWithFormat:@"%i|%@", versionCount, uuid];
      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
      NSString *documentsDirectory = [paths objectAtIndex:0];
            
            
      NSString *indexPath = [NSString stringWithFormat:@"%@/%@/index.html", documentsDirectory, uuid];
           
      NSURL *urlOverwrite = [NSURL fileURLWithPath:indexPath];
      NSURLRequest *request = [NSURLRequest requestWithURL:urlOverwrite];
            
      [prefs setInteger:1 forKey:@"redirected"];
      [prefs synchronize];

      NSLog(@"Redirecting to: %@", indexPath);
      [self.webView loadRequest:request];
    }
}

- (struct JsonHttpResponse) httpRequest:(NSString *) endpoint {
    //NSString *baseUrl = @"http://stage.apps.ionic.io";
    NSString *baseUrl = @"http://ionic-dash-local.ngrok.com";
    NSString *url = [NSString stringWithFormat:@"%@%@", baseUrl, endpoint];
    
    NSDictionary* headers = @{@"accept": @"application/json"};
    
    UNIHTTPJsonResponse* result = [[UNIRest get:^(UNISimpleRequest *request) {
        [request setUrl: url];
        [request setHeaders:headers];
    }] asJson];
    
    JsonHttpResponse response;

    /*if (error) {
        response->message = (@"%@", error);
        response->json = nil;
    } else {*/
        response.message = nil;
        response.json = [NSJSONSerialization JSONObjectWithData:result.rawBody options:kNilOptions error:nil];
    //}
    
    return response;
}

- (NSMutableArray *) getMyVersions {
    NSMutableArray *versions;
    NSArray *versionsLoaded = [[NSUserDefaults standardUserDefaults] arrayForKey:@"my_versions"];
    if (versionsLoaded != nil) {
        versions = [versionsLoaded mutableCopy];
    } else {
        versions = [[NSMutableArray alloc] initWithCapacity:5];
    }
    
    return versions;
}

- (bool) hasVersion:(NSString *) uuid {
    NSArray *versions = [self getMyVersions];
    
    NSLog(@"Versions: %@", versions);
    
    for (id version in versions) {
        NSArray *version_parts = [version componentsSeparatedByString:@"|"];
        NSString *version_uuid = version_parts[1];
        
        NSLog(@"version_uuid: %@, uuid: %@", version_uuid, uuid);
        if ([version_uuid isEqualToString:uuid]) {
            return true;
        }
    }
    
    return false;
}

- (void) saveVersion:(NSString *) uuid {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSMutableArray *versions = [self getMyVersions];
    
    int versionCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"version_count"];
    
    if (versionCount) {
        versionCount += 1;
    } else {
        versionCount = 1;
    }
    
    [prefs setInteger:versionCount forKey:@"version_count"];
    [prefs synchronize];
    
    NSString *versionString = [NSString stringWithFormat:@"%i|%@", versionCount, uuid];
    
    [versions addObject:versionString];
    
    [prefs setObject:versions forKey:@"my_versions"];
    [prefs synchronize];
    
    [self cleanupVersions];
}

- (void) cleanupVersions {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSMutableArray *versions = [self getMyVersions];
    
    int versionCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"version_count"];
    
    if (versionCount && versionCount > 3) {
        NSInteger threshold = versionCount - 3;
        
        NSInteger count = [versions count];
        for (NSInteger index = (count - 1); index >= 0; index--) {
            NSString *versionString = versions[index];
            NSArray *version_parts = [versionString componentsSeparatedByString:@"|"];
            NSInteger version_number = [version_parts[0] intValue];
            if (version_number < threshold) {
                [versions removeObjectAtIndex:index];
                [self removeVersion:version_parts[1]];
            }
        }
        
        NSLog(@"Version Count: %i", [versions count]);
        [prefs setObject:versions forKey:@"my_versions"];
        [prefs synchronize];
    }
}

- (void) removeVersion:(NSString *) uuid {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *pathToFolder = [NSString stringWithFormat:@"%@/%@/", documentsDirectory, uuid];
    
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:pathToFolder error:nil];
    
    NSLog(@"Removed Version %@ success? %d", uuid, success);
}

/* Delegate Methods for the DownloadManager */

- (void)downloadManager:(DownloadManager *)downloadManager downloadDidReceiveData:(Download *)download;
{
    // download failed
    // filename is retrieved from `download.filename`
    // the bytes downloaded thus far is `download.progressContentLength`
    // if the server reported the size of the file, it is returned by `download.expectedContentLength`
    
    self.progress = ((100.0 / download.expectedContentLength) * download.progressContentLength);
    
    NSLog(@"%.0f%%", ((100.0 / download.expectedContentLength) * download.progressContentLength));
    
    CDVPluginResult* pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:self.progress];
    [pluginResult setKeepCallbackAsBool:TRUE];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

- (void)didFinishLoadingAllForManager:(DownloadManager *)downloadManager
{
    // Save the upstream_uuid (what we just downloaded) to the uuid preference
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [[NSUserDefaults standardUserDefaults] objectForKey:@"uuid"];
    NSString *upstream_uuid = [[NSUserDefaults standardUserDefaults] objectForKey:@"upstream_uuid"];
    
    [prefs setObject: upstream_uuid forKey: @"uuid"];
    [prefs synchronize];
    
    NSLog(@"UUID is: %@ and upstream_uuid is: %@", uuid, upstream_uuid);
    
    [self saveVersion:upstream_uuid];
    
    NSLog(@"Download Finished...");
    CDVPluginResult* pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"true"];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

/* Delegate Methods for SSZipArchive */

- (void)zipArchiveProgressEvent:(NSInteger)loaded total:(NSInteger)total {
    float progress = ((100.0 / total) * loaded);
    NSLog(@"Zip Extraction: %.0f%%", progress);
    
    CDVPluginResult* pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:progress];
    [pluginResult setKeepCallbackAsBool:TRUE];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    
    if (progress == 100) {
        CDVPluginResult* pluginResult = nil;
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"done"];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}

@end