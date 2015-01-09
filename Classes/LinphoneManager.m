/* LinphoneManager.h
 *
 * Copyright (C) 2011  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */              

#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <sys/sysctl.h>

#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTCallCenter.h>

#import "LinphoneManager.h"
#import "LinphoneCoreSettingsStore.h"
#import "ChatModel.h"

#include "linphone/linphonecore_utils.h"
#include "lpconfig.h"

#define LINPHONE_LOGS_MAX_ENTRY 5000

static void audioRouteChangeListenerCallback (
                                              void                   *inUserData,                                 // 1
                                              AudioSessionPropertyID inPropertyID,                                // 2
                                              UInt32                 inPropertyValueSize,                         // 3
                                              const void             *inPropertyValue                             // 4
                                              );
static LinphoneCore* theLinphoneCore = nil;
static LinphoneManager* theLinphoneManager = nil;

const char *const LINPHONERC_APPLICATION_KEY = "app";

NSString *const kLinphoneCoreUpdate = @"LinphoneCoreUpdate";
NSString *const kLinphoneDisplayStatusUpdate = @"LinphoneDisplayStatusUpdate";
NSString *const kLinphoneTextReceived = @"LinphoneTextReceived";
NSString *const kLinphoneCallUpdate = @"LinphoneCallUpdate";
NSString *const kLinphoneRegistrationUpdate = @"LinphoneRegistrationUpdate";
NSString *const kLinphoneAddressBookUpdate = @"LinphoneAddressBookUpdate";
NSString *const kLinphoneMainViewChange = @"LinphoneMainViewChange";
NSString *const kLinphoneLogsUpdate = @"LinphoneLogsUpdate";
NSString *const kLinphoneSettingsUpdate = @"LinphoneSettingsUpdate";
NSString *const kLinphoneBluetoothAvailabilityUpdate = @"LinphoneBluetoothAvailabilityUpdate";



extern void libmsilbc_init();
#ifdef HAVE_AMR
extern void libmsamr_init();
#endif

#ifdef HAVE_X264
extern void libmsx264_init();
#endif
#define FRONT_CAM_NAME "AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:1" /*"AV Capture: Front Camera"*/
#define BACK_CAM_NAME "AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:0" /*"AV Capture: Back Camera"*/

#if defined (HAVE_SILK)
extern void libmssilk_init(); 
#endif

#if HAVE_G729
extern  void libmsbcg729_init();
#endif
@implementation LinphoneCallAppData
- (id)init {
    if ((self = [super init])) {
		self->batteryWarningShown = FALSE;
        self->notification = nil;
		self->videoRequested = FALSE;
        self->userInfos = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	[self->userInfos release];
	[super dealloc];
}
@end
@implementation LinphoneManager

@synthesize connectivity;
@synthesize network;
@synthesize frontCamId;
@synthesize backCamId;
@synthesize database;
@synthesize fastAddressBook;
@synthesize pushNotificationToken;
@synthesize sounds;
@synthesize logs;
@synthesize speakerEnabled;
@synthesize bluetoothAvailable;
@synthesize bluetoothEnabled;
@synthesize photoLibrary;

struct codec_name_pref_table{
    const char *name;
    int rate;
    NSString *prefname;
};

struct codec_name_pref_table codec_pref_table[]={
	{ "speex", 8000, @"speex_8k_preference" },
	{ "speex", 16000, @"speex_16k_preference" },
	{ "silk", 24000, @"silk_24k_preference" },
	{ "silk", 16000, @"silk_16k_preference" },
	{ "amr", 8000, @"amr_preference" },
    { "gsm", 8000, @"gsm_preference" },
	{ "ilbc", 8000, @"ilbc_preference"},
	{ "pcmu", 8000, @"pcmu_preference"},
	{ "pcma", 8000, @"pcma_preference"},
	{ "g722", 8000, @"g722_preference"},
	{ "g729", 8000, @"g729_preference"},
	{ "mp4v-es", 90000, @"mp4v-es_preference"},
	{ "h264", 90000, @"h264_preference"},
	{ "vp8", 90000, @"vp8_preference"},
	{ "mpeg4-generic", 44100, @"aaceld_44k_preference"},
	{ "mpeg4-generic", 22050, @"aaceld_22k_preference"},
	{ "opus", 48000, @"opus_preference"},
	{ NULL,0,Nil }
};

+ (NSString *)getPreferenceForCodec: (const char*) name withRate: (int) rate{
	int i;
	for(i=0;codec_pref_table[i].name!=NULL;++i){
		if (strcasecmp(codec_pref_table[i].name,name)==0 && codec_pref_table[i].rate==rate)
			return codec_pref_table[i].prefname;
	}
	return Nil;
}

+ (NSSet *)unsupportedCodecs {
    NSMutableSet *set = [NSMutableSet set];
	for(int i=0;codec_pref_table[i].name!=NULL;++i) {
        if(linphone_core_find_payload_type(theLinphoneCore,codec_pref_table[i].name
										   , codec_pref_table[i].rate,LINPHONE_FIND_PAYLOAD_IGNORE_CHANNELS) == NULL) {
            [set addObject:codec_pref_table[i].prefname];
		}
	}
	return set;
}

+ (BOOL)runningOnIpad {
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
    return NO;
#endif
}

+ (BOOL)isNotIphone3G
{
	static BOOL done=FALSE;
	static BOOL result;
	if (!done){
		size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *machine = malloc(size);
		sysctlbyname("hw.machine", machine, &size, NULL, 0);
		NSString *platform = [[NSString alloc ] initWithUTF8String:machine];
		free(machine);
        
		result = ![platform isEqualToString:@"iPhone1,2"];
        
		[platform release];
		done=TRUE;
	}
    return result;
}

+ (NSString *)getUserAgent {
    return [NSString stringWithFormat:@"LinphoneIphone/%@ (Linphone/%s; Apple %@/%@)",
            [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey],
            linphone_core_get_version(),
            [UIDevice currentDevice].systemName,
            [UIDevice currentDevice].systemVersion];
}

+ (LinphoneManager*)instance {
    if(theLinphoneManager == nil) {
        theLinphoneManager = [LinphoneManager alloc];
        [theLinphoneManager init];
    }
	return theLinphoneManager;
}

#ifdef DEBUG
+ (void)instanceRelease {
    if(theLinphoneManager != nil) {
        [theLinphoneManager release];
        theLinphoneManager = nil;
    }
}
#endif

#pragma mark - Lifecycle Functions

- (id)init {
    if ((self = [super init])) {
        AudioSessionInitialize(NULL, NULL, NULL, NULL);
        OSStatus lStatus = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, self);
        if (lStatus) {
            [LinphoneLogger logc:LinphoneLoggerError format:"cannot register route change handler [%ld]",lStatus];
        }
        
        // Sounds
        {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"ring" ofType:@"wav"];
            sounds.call = 0;
            OSStatus status = AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:path], &sounds.call);
            if(status != 0){
                [LinphoneLogger log:LinphoneLoggerWarning format:@"Can't set \"call\" system sound"];
            }
        }
        {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"msg" ofType:@"wav"];
            sounds.message = 0;
            OSStatus status = AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:path], &sounds.message);
            if(status != 0){
                [LinphoneLogger log:LinphoneLoggerWarning format:@"Can't set \"message\" system sound"];
            }
        }
        
        logs = [[NSMutableArray alloc] init];
        database = NULL;
        speakerEnabled = FALSE;
        bluetoothEnabled = FALSE;
        [self openDatabase];
        [self copyDefaultSettings];
        pendindCallIdFromRemoteNotif = [[NSMutableArray alloc] init ];
        photoLibrary = [[ALAssetsLibrary alloc] init];

    }
    return self;
}

- (void)dealloc {
    if(sounds.call) {
        AudioServicesDisposeSystemSoundID(sounds.call);
    }
    if(sounds.message) {
        AudioServicesDisposeSystemSoundID(sounds.message);
    }
    
    [fastAddressBook release];
    [self closeDatabase];
    [logs release];
    
    OSStatus lStatus = AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, self);
	if (lStatus) {
		[LinphoneLogger logc:LinphoneLoggerError format:"cannot un register route change handler [%ld]", lStatus];
	}
    
    [photoLibrary release];
	[pendindCallIdFromRemoteNotif release];
    [super dealloc];
}


#pragma mark - Database Functions

- (void)openDatabase {
    NSString *databasePath = [LinphoneManager documentFile:@"chat_database.sqlite"];
	NSFileManager *filemgr = [NSFileManager defaultManager];
	//[filemgr removeItemAtPath:databasePath error:nil];
	BOOL firstInstall= ![filemgr fileExistsAtPath: databasePath ];
    
	if(sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
        [LinphoneLogger log:LinphoneLoggerError format:@"Can't open \"%@\" sqlite3 database.", databasePath];
		return;
    } 
	
	if (firstInstall) {
		char *errMsg;
		//better to create the db from the code
		const char *sql_stmt = "CREATE TABLE chat (id INTEGER PRIMARY KEY AUTOINCREMENT, localContact TEXT NOT NULL, remoteContact TEXT NOT NULL, direction INTEGER, message TEXT NOT NULL, time NUMERIC, read INTEGER, state INTEGER)";
			
			if (sqlite3_exec(database, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
				[LinphoneLogger logc:LinphoneLoggerError format:"Can't create table error[%s] ", errMsg];
			}
	}
	
	[filemgr release];
}

- (void)closeDatabase {
    if(database != NULL) {
        if(sqlite3_close(database) != SQLITE_OK) {
            [LinphoneLogger logc:LinphoneLoggerError format:"Can't close sqlite3 database."];
        }
    }
}


#pragma mark - Linphone Core Functions

+ (LinphoneCore*)getLc {
	if (theLinphoneCore==nil) {
		@throw([NSException exceptionWithName:@"LinphoneCoreException" reason:@"Linphone core not initialized yet" userInfo:nil]);
	}
	return theLinphoneCore;
}

+ (BOOL)isLcReady {
    return theLinphoneCore != nil;
}


#pragma mark - Logs Functions

//generic log handler for debug version
void linphone_iphone_log_handler(int lev, const char *fmt, va_list args){
	NSString* format = [[NSString alloc] initWithUTF8String:fmt];
	NSLogv(format, args);
	NSString* formatedString = [[NSString alloc] initWithFormat:format arguments:args];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if([[LinphoneManager instance].logs count] >= LINPHONE_LOGS_MAX_ENTRY) {
            [[LinphoneManager instance].logs removeObjectAtIndex:0];
        }
        [[LinphoneManager instance].logs addObject:formatedString];
        
        // Post event
        NSDictionary *dict = [NSDictionary dictionaryWithObject:formatedString forKey:@"log"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneLogsUpdate object:[LinphoneManager instance] userInfo:dict];
    });
    
	[formatedString release];
    [format release];
}

//Error/warning log handler 
static void linphone_iphone_log(struct _LinphoneCore * lc, const char * message) {
	NSString* log = [NSString stringWithCString:message encoding:[NSString defaultCStringEncoding]]; 
	NSLog(log, NULL);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if([[LinphoneManager instance].logs count] >= LINPHONE_LOGS_MAX_ENTRY) {
            [[LinphoneManager instance].logs removeObjectAtIndex:0];
        }
        [[LinphoneManager instance].logs addObject:log];
        
        // Post event
        NSDictionary *dict = [NSDictionary dictionaryWithObject:log forKey:@"log"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneLogsUpdate object:[LinphoneManager instance] userInfo:dict];
    });
}


#pragma mark - Display Status Functions

- (void)displayStatus:(NSString*) message {
    // Post event
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                           message, @"message", 
                           nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneDisplayStatusUpdate object:self userInfo:dict];
}


static void linphone_iphone_display_status(struct _LinphoneCore * lc, const char * message) {
    NSString* status = [[NSString alloc] initWithCString:message encoding:[NSString defaultCStringEncoding]];
	[(LinphoneManager*)linphone_core_get_user_data(lc)  displayStatus:status];
    [status release];
}


#pragma mark - Call State Functions

- (void)onCall:(LinphoneCall*)call StateChanged:(LinphoneCallState)state withMessage:(const char *)message {
    
	// Handling wrapper
	LinphoneCallAppData* data=(LinphoneCallAppData*)linphone_call_get_user_pointer(call);
	if (!data) {
        data = [[LinphoneCallAppData alloc] init];
        linphone_call_set_user_pointer(call, data);
    }
	
    const LinphoneAddress *addr = linphone_call_get_remote_address(call);
    NSString* address = nil;
    if(addr != NULL) {
        BOOL useLinphoneAddress = true;
        // contact name
        char* lAddress = linphone_address_as_string_uri_only(addr);
        if(lAddress) {
            NSString *normalizedSipAddress = [FastAddressBook normalizeSipURI:[NSString stringWithUTF8String:lAddress]];
            ABRecordRef contact = [fastAddressBook getContact:normalizedSipAddress];
            if(contact) {
                address = [FastAddressBook getContactDisplayName:contact];
                useLinphoneAddress = false;
            }
            ms_free(lAddress);
        }
        if(useLinphoneAddress) {
            const char* lDisplayName = linphone_address_get_display_name(addr);
            const char* lUserName = linphone_address_get_username(addr);
            if (lDisplayName)
                address = [NSString stringWithUTF8String:lDisplayName];
            else if(lUserName)
                address = [NSString stringWithUTF8String:lUserName];
        }
    }
    if(address == nil) {
        address = @"Unknown";
    }
    
	if (state == LinphoneCallIncomingReceived) {
        
		/*first step is to re-enable ctcall center*/
		CTCallCenter* lCTCallCenter = [[CTCallCenter alloc] init];
		
		/*should we reject this call ?*/
		if ([lCTCallCenter currentCalls]!=nil) {
			char *tmp=linphone_call_get_remote_address_as_string(call);
			if (tmp) {
				[LinphoneLogger logc:LinphoneLoggerLog format:"Mobile call ongoing... rejecting call from [%s]",tmp];
				ms_free(tmp);
			}
			linphone_core_decline_call(theLinphoneCore, call,LinphoneReasonBusy);
			[lCTCallCenter release];
			return;
		}
		[lCTCallCenter release];
		
		if(	[[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
		   && [UIApplication sharedApplication].applicationState !=  UIApplicationStateActive) {
			
			LinphoneCallLog* callLog=linphone_call_get_call_log(call);
			NSString* callId=[NSString stringWithUTF8String:linphone_call_log_get_call_id(callLog)];
			
			if (![[LinphoneManager instance] shouldAutoAcceptCallForCallId:callId]){
				// case where a remote notification is not already received
				// Create a new local notification
				data->notification = [[UILocalNotification alloc] init];
				if (data->notification) {
					data->notification.repeatInterval = 0;
					data->notification.alertBody =[NSString  stringWithFormat:NSLocalizedString(@"IC_MSG",nil), address];
					data->notification.alertAction = NSLocalizedString(@"Answer", nil);
					data->notification.soundName = @"ring.caf";
					data->notification.userInfo = [NSDictionary dictionaryWithObject:callId forKey:@"callId"];
					
					[[UIApplication sharedApplication] presentLocalNotificationNow:data->notification];
					
					if (!incallBgTask){
						incallBgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^{
							[LinphoneLogger log:LinphoneLoggerWarning format:@"Call cannot ring any more, too late"];
						}];
					}
					
				}
			}
		}
	}

    // Disable speaker when no more call
    if ((state == LinphoneCallEnd || state == LinphoneCallError)) {
        if(linphone_core_get_calls_nb(theLinphoneCore) == 0) {
            [self setSpeakerEnabled:FALSE];
			[self removeCTCallCenterCb];
            bluetoothAvailable = FALSE;
            bluetoothEnabled = FALSE;
            /*IOS specific*/
            linphone_core_start_dtmf_stream(theLinphoneCore);
		}
		if (incallBgTask) {
			[[UIApplication sharedApplication]  endBackgroundTask:incallBgTask];
			incallBgTask=0;
		}       
        if(data != nil && data->notification != nil) {
            LinphoneCallLog *log = linphone_call_get_call_log(call);
        
            // cancel local notif if needed
            [[UIApplication sharedApplication] cancelLocalNotification:data->notification];
            [data->notification release];
            data->notification = nil;
            
            if(log == NULL || linphone_call_log_get_status(log) == LinphoneCallMissed) {
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                notification.repeatInterval = 0;
                notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"You missed a call from %@", nil), address];
                notification.alertAction = NSLocalizedString(@"Show", nil);
                notification.userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:linphone_call_log_get_call_id(log)] forKey:@"callLog"];
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                [notification release];
            }
            
        }
    }
    
	if(state == LinphoneCallReleased) {
        if(data != NULL) {
            [data release];
            linphone_call_set_user_pointer(call, NULL);
        }
    }
    
    // Enable speaker when video
    if(state == LinphoneCallIncomingReceived ||
       state == LinphoneCallOutgoingInit ||
       state == LinphoneCallConnected ||
       state == LinphoneCallStreamsRunning) {
        if (linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
            [self setSpeakerEnabled:TRUE];
        }
    }
    if (state == LinphoneCallConnected && !mCallCenter) {
		/*only register CT call center CB for connected call*/
		[self setupGSMInteraction];
	}
    // Post event
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSValue valueWithPointer:call], @"call",
                           [NSNumber numberWithInt:state], @"state", 
                           [NSString stringWithUTF8String:message], @"message", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneCallUpdate object:self userInfo:dict];
}

static void linphone_iphone_call_state(LinphoneCore *lc, LinphoneCall* call, LinphoneCallState state,const char* message) {
	[(LinphoneManager*)linphone_core_get_user_data(lc) onCall:call StateChanged: state withMessage:  message];
}


#pragma mark - Transfert State Functions

static void linphone_iphone_transfer_state_changed(LinphoneCore* lc, LinphoneCall* call, LinphoneCallState state) {
}


#pragma mark - Registration State Functions

- (void)onRegister:(LinphoneCore *)lc cfg:(LinphoneProxyConfig*) cfg state:(LinphoneRegistrationState) state message:(const char*) message {
    [LinphoneLogger logc:LinphoneLoggerLog format:"NEW REGISTRATION STATE: '%s' (message: '%s')", linphone_registration_state_to_string(state), message];
	if (state==LinphoneRegistrationOk)
		[LinphoneManager instance]->stopWaitingRegisters=TRUE;
    
    // Post event
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:state], @"state", 
                          [NSValue valueWithPointer:cfg], @"cfg",
                          [NSString stringWithUTF8String:message], @"message", 
                          nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneRegistrationUpdate object:self userInfo:dict];
}

static void linphone_iphone_registration_state(LinphoneCore *lc, LinphoneProxyConfig* cfg, LinphoneRegistrationState state,const char* message) {
	[(LinphoneManager*)linphone_core_get_user_data(lc) onRegister:lc cfg:cfg state:state message:message];
}


#pragma mark - Text Received Functions

- (void)onMessageReceived:(LinphoneCore *)lc room:(LinphoneChatRoom *)room  message:(LinphoneChatMessage*)msg {
    
    char *fromStr = linphone_address_as_string_uri_only(linphone_chat_message_get_from(msg));
    if(fromStr == NULL)
        return;
    
    // Save message in database
    ChatModel *chat = [[ChatModel alloc] init];
    [chat setLocalContact:@""];
    [chat setRemoteContact:[NSString stringWithUTF8String:fromStr]];
    if (linphone_chat_message_get_external_body_url(msg)) {
		[chat setMessage:[NSString stringWithUTF8String:linphone_chat_message_get_external_body_url(msg)]];
	} else {
		[chat setMessage:[NSString stringWithUTF8String:linphone_chat_message_get_text(msg)]];
    }
	[chat setDirection:[NSNumber numberWithInt:1]];
    [chat setTime:[NSDate dateWithTimeIntervalSince1970:linphone_chat_message_get_time(msg)]];
    [chat setRead:[NSNumber numberWithInt:0]];
    [chat create];
    
    ms_free(fromStr);
    
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
		&& [UIApplication sharedApplication].applicationState !=  UIApplicationStateActive) {
        
        NSString* address = [chat remoteContact];
        NSString *normalizedSipAddress = [FastAddressBook normalizeSipURI:address];
        ABRecordRef contact = [fastAddressBook getContact:normalizedSipAddress];
        if(contact) {
            address = [FastAddressBook getContactDisplayName:contact];
        } else {
            if ([[LinphoneManager instance] lpConfigBoolForKey:@"show_contacts_emails_preference"] == true) {
                LinphoneAddress *linphoneAddress = linphone_address_new([normalizedSipAddress cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                address = [NSString stringWithUTF8String:linphone_address_get_username(linphoneAddress)];
                linphone_address_destroy(linphoneAddress);
            }
        }
        if(address == nil) {
            address = @"Unknown";
        }

		// Create a new notification
		UILocalNotification* notif = [[[UILocalNotification alloc] init] autorelease];
		if (notif) {
			notif.repeatInterval = 0;
			notif.alertBody = [NSString  stringWithFormat:NSLocalizedString(@"IM_MSG",nil), address];
			notif.alertAction = NSLocalizedString(@"Show", nil);
			notif.soundName = @"msg.caf";
			notif.userInfo = [NSDictionary dictionaryWithObject:[chat remoteContact] forKey:@"chat"];
			
			
			[[UIApplication sharedApplication] presentLocalNotificationNow:notif];
		}
	}
    
    // Post event
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSValue valueWithPointer:room], @"room", 
							[NSValue valueWithPointer:linphone_chat_message_get_from(msg)], @"from",
							chat.message, @"message", 
							chat, @"chat",
                           nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneTextReceived object:self userInfo:dict];
    [chat release];
}

static void linphone_iphone_message_received(LinphoneCore *lc, LinphoneChatRoom *room, LinphoneChatMessage *message) {
    [(LinphoneManager*)linphone_core_get_user_data(lc) onMessageReceived:lc room:room message:message];
}


#pragma mark - Network Functions

+ (void)kickOffNetworkConnection {
	/*start a new thread to avoid blocking the main ui in case of peer host failure*/
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"192.168.0.200"/*"linphone.org"*/, 15000, nil, &writeStream);
        CFWriteStreamOpen (writeStream);
        const char* buff="hello";
        CFWriteStreamWrite (writeStream,(const UInt8*)buff,strlen(buff));
        CFWriteStreamClose (writeStream);
        CFRelease(writeStream);
    });
}	

static void showNetworkFlags(SCNetworkReachabilityFlags flags){
	[LinphoneLogger logc:LinphoneLoggerLog format:"Network connection flags:"];
	if (flags==0) [LinphoneLogger logc:LinphoneLoggerLog format:"no flags."];
	if (flags & kSCNetworkReachabilityFlagsTransientConnection)
		[LinphoneLogger logc:LinphoneLoggerLog format:"kSCNetworkReachabilityFlagsTransientConnection"];
	if (flags & kSCNetworkReachabilityFlagsReachable)
		[LinphoneLogger logc:LinphoneLoggerLog format:"kSCNetworkReachabilityFlagsReachable"];
	if (flags & kSCNetworkReachabilityFlagsConnectionRequired)
		[LinphoneLogger logc:LinphoneLoggerLog format:"kSCNetworkReachabilityFlagsConnectionRequired"];
	if (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)
		[LinphoneLogger logc:LinphoneLoggerLog format:"kSCNetworkReachabilityFlagsConnectionOnTraffic"];
	if (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)
		[LinphoneLogger logc:LinphoneLoggerLog format:"kSCNetworkReachabilityFlagsConnectionOnDemand"];
	if (flags & kSCNetworkReachabilityFlagsIsLocalAddress)
		[LinphoneLogger logc:LinphoneLoggerLog format:"kSCNetworkReachabilityFlagsIsLocalAddress"];
	if (flags & kSCNetworkReachabilityFlagsIsDirect)
		[LinphoneLogger logc:LinphoneLoggerLog format:"kSCNetworkReachabilityFlagsIsDirect"];
	if (flags & kSCNetworkReachabilityFlagsIsWWAN)
		[LinphoneLogger logc:LinphoneLoggerLog format:"kSCNetworkReachabilityFlagsIsWWAN"];
}

void networkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* nilCtx){
	showNetworkFlags(flags);
	LinphoneManager* lLinphoneMgr = [LinphoneManager instance];
	SCNetworkReachabilityFlags networkDownFlags=kSCNetworkReachabilityFlagsConnectionRequired |kSCNetworkReachabilityFlagsConnectionOnTraffic | kSCNetworkReachabilityFlagsConnectionOnDemand;

	if (theLinphoneCore != nil) {
		LinphoneProxyConfig* proxy;
		linphone_core_get_default_proxy(theLinphoneCore, &proxy);

        struct NetworkReachabilityContext* ctx = nilCtx ? ((struct NetworkReachabilityContext*)nilCtx) : 0;
		if ((flags == 0) || (flags & networkDownFlags)) {
			linphone_core_set_network_reachable(theLinphoneCore, false);
			lLinphoneMgr.connectivity = none;
			[LinphoneManager kickOffNetworkConnection];
		} else {
			Connectivity  newConnectivity;
			BOOL isWifiOnly = lp_config_get_int(linphone_core_get_config(theLinphoneCore), LINPHONERC_APPLICATION_KEY, "wifi_only_preference",FALSE);
            if (!ctx || ctx->testWWan)
                newConnectivity = flags & kSCNetworkReachabilityFlagsIsWWAN ? wwan:wifi;
            else
                newConnectivity = wifi;

			if (newConnectivity == wwan 
				&& proxy 
				&& isWifiOnly 
				&& (lLinphoneMgr.connectivity == newConnectivity || lLinphoneMgr.connectivity == none)) {
				linphone_proxy_config_expires(proxy, 0);
			} else if (proxy){
				int defaultExpire = [[LinphoneManager instance] lpConfigIntForKey:@"default_expires"];
				if (defaultExpire>=0)
					linphone_proxy_config_expires(proxy, defaultExpire);
				//else keep default value from linphonecore
			}
			
			if (lLinphoneMgr.connectivity != newConnectivity) {
				// connectivity has changed
				linphone_core_set_network_reachable(theLinphoneCore,false);
				if (newConnectivity == wwan && proxy && isWifiOnly) {
					linphone_proxy_config_expires(proxy, 0);
				} 
				linphone_core_set_network_reachable(theLinphoneCore,true);
				[LinphoneLogger logc:LinphoneLoggerLog format:"Network connectivity changed to type [%s]",(newConnectivity==wifi?"wifi":"wwan")];
				[lLinphoneMgr waitForRegisterToArrive];
			}
			lLinphoneMgr.connectivity=newConnectivity;
		}
		if (ctx && ctx->networkStateChanged) {
            (*ctx->networkStateChanged)(lLinphoneMgr.connectivity);
        }
	}
}

- (void)setupNetworkReachabilityCallback {
	SCNetworkReachabilityContext *ctx=NULL;
    //any internet cnx
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
	
    if (proxyReachability) {
        [LinphoneLogger logc:LinphoneLoggerLog format:"Cancelling old network reachability"];
        SCNetworkReachabilityUnscheduleFromRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRelease(proxyReachability);
        proxyReachability = nil;
    }
    
    proxyReachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);

	if (!SCNetworkReachabilitySetCallback(proxyReachability, (SCNetworkReachabilityCallBack)networkReachabilityCallBack, ctx)){
		[LinphoneLogger logc:LinphoneLoggerError format:"Cannot register reachability cb: %s", SCErrorString(SCError())];
		return;
	}
	if(!SCNetworkReachabilityScheduleWithRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)){
		[LinphoneLogger logc:LinphoneLoggerError format:"Cannot register schedule reachability cb: %s", SCErrorString(SCError())];
		return;
	}
	// this check is to know network connectivity right now without waiting for a change. Don'nt remove it unless you have good reason. Jehan
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(proxyReachability, &flags)) {
		networkReachabilityCallBack(proxyReachability,flags,nil);
	}
}

- (NetworkType)network {
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *subviews = [[[app valueForKey:@"statusBar"] valueForKey:@"foregroundView"]    subviews];
    NSNumber *dataNetworkItemView = nil;
    
    for (id subview in subviews) {
        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
            dataNetworkItemView = subview;
            break;
        }
    }
    NSNumber *number = (NSNumber*)[dataNetworkItemView valueForKey:@"dataNetworkType"];
    return [number intValue];
}


#pragma mark - 

static LinphoneCoreVTable linphonec_vtable = {
	.show =NULL,
	.call_state_changed =(LinphoneCoreCallStateChangedCb)linphone_iphone_call_state,
	.registration_state_changed = linphone_iphone_registration_state,
	.notify_presence_recv=NULL,
	.new_subscription_request = NULL,
	.auth_info_requested = NULL,
	.display_status = linphone_iphone_display_status,
	.display_message=linphone_iphone_log,
	.display_warning=linphone_iphone_log,
	.display_url=NULL,
	.text_received=NULL,
	.message_received=linphone_iphone_message_received,
	.dtmf_received=NULL,
    .transfer_state_changed=linphone_iphone_transfer_state_changed
};

//scheduling loop
- (void)iterate {
	linphone_core_iterate(theLinphoneCore);
}

- (void)startLibLinphone {
    if (theLinphoneCore != nil) {
        [LinphoneLogger logc:LinphoneLoggerLog format:"linphonecore is already created"];
        return;
    }
	
	//get default config from bundle
	NSString* factoryConfig = [LinphoneManager bundleFile:[LinphoneManager runningOnIpad]?@"linphonerc-factory~ipad":@"linphonerc-factory"];
	NSString *confiFileName = [LinphoneManager documentFile:@".linphonerc"];
	NSString *zrtpSecretsFileName = [LinphoneManager documentFile:@"zrtp_secrets"];
	const char* lRootCa = [[LinphoneManager bundleFile:@"rootca.pem"] cStringUsingEncoding:[NSString defaultCStringEncoding]];
	connectivity = none;
	signal(SIGPIPE, SIG_IGN);
	//log management	
	
	libmsilbc_init();
#if defined (HAVE_SILK)
    libmssilk_init(); 
#endif	
#ifdef HAVE_AMR
    libmsamr_init(); //load amr plugin if present from the liblinphone sdk
#endif	
#ifdef HAVE_X264
	libmsx264_init(); //load x264 plugin if present from the liblinphone sdk
#endif

#if HAVE_G729
	libmsbcg729_init(); // load g729 plugin
#endif
	/* Initialize linphone core*/
    
	/*to make sure we don't loose debug trace*/
	if ([[NSUserDefaults standardUserDefaults]  boolForKey:@"debugenable_preference"]) {
		linphone_core_enable_logs_with_cb((OrtpLogFunc)linphone_iphone_log_handler);
        ortp_set_log_level_mask(ORTP_DEBUG|ORTP_MESSAGE|ORTP_WARNING|ORTP_ERROR|ORTP_FATAL);
	}
	[LinphoneLogger logc:LinphoneLoggerLog format:"Create linphonecore"];

	theLinphoneCore = linphone_core_new (&linphonec_vtable
										 , [confiFileName cStringUsingEncoding:[NSString defaultCStringEncoding]]
										 , [factoryConfig cStringUsingEncoding:[NSString defaultCStringEncoding]]
										 ,self);
	linphone_core_set_user_agent(theLinphoneCore,"LinphoneIPhone",
                                 [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey] UTF8String]);
	[_contactSipField release];
	_contactSipField = [[self lpConfigStringForKey:@"contact_im_type_value" withDefault:@"SIP"] retain];
	

	fastAddressBook = [[FastAddressBook alloc] init];
	
    linphone_core_set_root_ca(theLinphoneCore, lRootCa);
	// Set audio assets
	const char* lRing = [[LinphoneManager bundleFile:@"ring.wav"] cStringUsingEncoding:[NSString defaultCStringEncoding]];
	linphone_core_set_ring(theLinphoneCore, lRing);
	const char* lRingBack = [[LinphoneManager bundleFile:@"ringback.wav"] cStringUsingEncoding:[NSString defaultCStringEncoding]];
	linphone_core_set_ringback(theLinphoneCore, lRingBack);
    const char* lPlay = [[LinphoneManager bundleFile:@"hold.wav"] cStringUsingEncoding:[NSString defaultCStringEncoding]];
	linphone_core_set_play_file(theLinphoneCore, lPlay);
	
	linphone_core_set_zrtp_secrets_file(theLinphoneCore, [zrtpSecretsFileName cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    [self setupNetworkReachabilityCallback];
	
	// start scheduler
	mIterateTimer = [NSTimer scheduledTimerWithTimeInterval:0.02
													 target:self 
												   selector:@selector(iterate) 
												   userInfo:nil 
													repeats:YES];
	//init audio session
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	BOOL bAudioInputAvailable= [audioSession inputIsAvailable];
    [audioSession setDelegate:self];
	
	NSError* err;
	[audioSession setActive:NO error: &err]; 
	if(!bAudioInputAvailable){
		UIAlertView* error = [[UIAlertView alloc]	initWithTitle:NSLocalizedString(@"No microphone",nil)
														message:NSLocalizedString(@"You need to plug a microphone to your device to use this application.",nil) 
													   delegate:nil 
											  cancelButtonTitle:NSLocalizedString(@"Ok",nil) 
											  otherButtonTitles:nil ,nil];
		[error show];
        [error release];
	}
    
    NSString* path = [LinphoneManager bundleFile:@"nowebcamCIF.jpg"];
    if (path) {
        const char* imagePath = [path cStringUsingEncoding:[NSString defaultCStringEncoding]];
        [LinphoneLogger logc:LinphoneLoggerLog format:"Using '%s' as source image for no webcam", imagePath];
        linphone_core_set_static_picture(theLinphoneCore, imagePath);
    }
    
	/*DETECT cameras*/
	frontCamId= backCamId=nil;
	char** camlist = (char**)linphone_core_get_video_devices(theLinphoneCore);
		for (char* cam = *camlist;*camlist!=NULL;cam=*++camlist) {
			if (strcmp(FRONT_CAM_NAME, cam)==0) {
				frontCamId = cam;
				//great set default cam to front
				linphone_core_set_video_device(theLinphoneCore, cam);
			}
			if (strcmp(BACK_CAM_NAME, cam)==0) {
				backCamId = cam;
			}
			
		}

    NSUInteger cpucount = [[NSProcessInfo processInfo] processorCount];
	ms_set_cpu_count(cpucount);

	if (![LinphoneManager isNotIphone3G]){
		PayloadType *pt=linphone_core_find_payload_type(theLinphoneCore,"SILK",24000,-1);
		if (pt) {
			linphone_core_enable_payload_type(theLinphoneCore,pt,FALSE);
			[LinphoneLogger logc:LinphoneLoggerWarning format:"SILK/24000 and video disabled on old iPhone 3G"];
		}
		linphone_core_enable_video(theLinphoneCore, FALSE, FALSE);
	}
    
    

    
    [LinphoneLogger logc:LinphoneLoggerWarning format:"Linphone [%s]  started on [%s]"
               ,linphone_core_get_version()
               ,[[UIDevice currentDevice].model cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] 
		&& [UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground) {
		//go directly to bg mode
		[self resignActive];
	}
		
    
    // Post event
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSValue valueWithPointer:theLinphoneCore] forKey:@"core"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneCoreUpdate object:[LinphoneManager instance] userInfo:dict];
}

- (void)destroyLibLinphone {
	[mIterateTimer invalidate]; 
	//just in case
	[self removeCTCallCenterCb];
	
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	[audioSession setDelegate:nil];

	if (theLinphoneCore != nil) { //just in case application terminate before linphone core initialization
        [LinphoneLogger logc:LinphoneLoggerLog format:"Destroy linphonecore"];
		linphone_core_destroy(theLinphoneCore);
		theLinphoneCore = nil;
        
        // Post event
        NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSValue valueWithPointer:theLinphoneCore] forKey:@"core"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneCoreUpdate object:[LinphoneManager instance] userInfo:dict];
        
        SCNetworkReachabilityUnscheduleFromRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        if (proxyReachability)
            CFRelease(proxyReachability);
        proxyReachability=nil;
        
    }
}

static int comp_call_id(const LinphoneCall* call , const char *callid) {
	if (linphone_call_log_get_call_id(linphone_call_get_call_log(call)) == nil) {
		ms_error ("no callid for call [%p]", call);
		return 1;
	}
	return strcmp(linphone_call_log_get_call_id(linphone_call_get_call_log(call)), callid);
}

- (void)acceptCallForCallId:(NSString*)callid {
    //first, make sure this callid is not already involved in a call
	if ([LinphoneManager isLcReady]) {
		MSList* calls = (MSList*)linphone_core_get_calls(theLinphoneCore);
        MSList* call = ms_list_find_custom(calls, (MSCompareFunc)comp_call_id, [callid UTF8String]);
		if (call != NULL) {
            [self acceptCall:(LinphoneCall*)call->data];
			return;
		};
	}
}

- (void)enableAutoAnswerForCallId:(NSString*) callid {
    //first, make sure this callid is not already involved in a call
	if ([LinphoneManager isLcReady]) {
		MSList* calls = (MSList*)linphone_core_get_calls(theLinphoneCore);
		if (ms_list_find_custom(calls, (MSCompareFunc)comp_call_id, [callid UTF8String])) {
			[LinphoneLogger log:LinphoneLoggerWarning format:@"Call id [%@] already handled",callid];
			return;
		};
	}
	if ([pendindCallIdFromRemoteNotif count] > 10 /*max number of pending notif*/)
		[pendindCallIdFromRemoteNotif removeObjectAtIndex:0];
	[pendindCallIdFromRemoteNotif addObject:callid];
	
}

- (BOOL)shouldAutoAcceptCallForCallId:(NSString*) callId {
    for (NSString* pendingNotif in pendindCallIdFromRemoteNotif) {
		if ([pendingNotif  compare:callId] == NSOrderedSame) {
			[pendindCallIdFromRemoteNotif removeObject:pendingNotif];
			return TRUE;
		}
    }
    return FALSE;
}

- (BOOL)resignActive {
	linphone_core_stop_dtmf_stream(theLinphoneCore);

    return YES;
}

- (void)waitForRegisterToArrive{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
		&& [UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground) {
        stopWaitingRegisters = FALSE;
        [LinphoneLogger logc:LinphoneLoggerLog format:"Starting long running task for registering"];
        UIBackgroundTaskIdentifier bgid = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^{
            [LinphoneManager instance]->stopWaitingRegisters=TRUE;
            [LinphoneLogger logc:LinphoneLoggerLog format:"Expiration handler called"];
        }];
        for(int i=0;i<100 && (!stopWaitingRegisters);i++){
            linphone_core_iterate(theLinphoneCore);
            usleep(20000);
        }
        [LinphoneLogger logc:LinphoneLoggerLog format:"Ending long running task for registering"];
        [[UIApplication sharedApplication] endBackgroundTask:bgid];
    }
}

static int comp_call_state_paused  (const LinphoneCall* call, const void* param) {
	return linphone_call_get_state(call) != LinphoneCallPaused;
}

- (void) startCallPausedLongRunningTask {
	pausedCallBgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^{
		[LinphoneLogger log:LinphoneLoggerWarning format:@"Call cannot be paused any more, too late"];
	}];
	[LinphoneLogger log:LinphoneLoggerLog format:@"Long running task started, remaining [%g s] because at least one call is paused"
	 ,[[UIApplication  sharedApplication] backgroundTimeRemaining]];
}
- (BOOL)enterBackgroundMode {
	LinphoneProxyConfig* proxyCfg;
	linphone_core_get_default_proxy(theLinphoneCore, &proxyCfg);	
	
	
	if ((proxyCfg || linphone_core_get_calls_nb(theLinphoneCore) > 0) &&
        [[NSUserDefaults standardUserDefaults] boolForKey:@"backgroundmode_preference"]) {
        
        if(proxyCfg != NULL) {
            //For registration register
            [self refreshRegisters];
            //wait for registration answer
            int i=0;
            while (!linphone_proxy_config_is_registered(proxyCfg) && i++<40 ) {
                linphone_core_iterate(theLinphoneCore);
                usleep(100000);
            }
        }
		//register keepalive
		if ([[UIApplication sharedApplication] setKeepAliveTimeout:600/*(NSTimeInterval)linphone_proxy_config_get_expires(proxyCfg)*/ 
														   handler:^{
															   [LinphoneLogger logc:LinphoneLoggerWarning format:"keepalive handler"];
															   if (theLinphoneCore == nil) {
																   [LinphoneLogger logc:LinphoneLoggerWarning format:"It seems that Linphone BG mode was deactivated, just skipping"];
																   return;
															   }
															   //kick up network cnx, just in case
															   [self refreshRegisters];
															   linphone_core_iterate(theLinphoneCore);
														   }
			 ]) {
			
			
			[LinphoneLogger logc:LinphoneLoggerLog format:"keepalive handler succesfully registered"]; 
		} else {
			[LinphoneLogger logc:LinphoneLoggerLog format:"keepalive handler cannot be registered"];
		}
		LinphoneCall* currentCall = linphone_core_get_current_call(theLinphoneCore);
		const MSList* callList = linphone_core_get_calls(theLinphoneCore);
		if (!currentCall //no active call
			&& callList // at least one call in a non active state
			&& ms_list_find_custom((MSList*)callList, (MSCompareFunc) comp_call_state_paused, NULL)) {
			[self startCallPausedLongRunningTask];
		}
		return YES;
	}
	else {
		[LinphoneLogger logc:LinphoneLoggerLog format:"Entering lite bg mode"];
		[self destroyLibLinphone];
        return NO;
	}
}

- (void)becomeActive {
    [self refreshRegisters];
    if (pausedCallBgTask) {
		[[UIApplication sharedApplication]  endBackgroundTask:pausedCallBgTask];
		pausedCallBgTask=0;
	}
    if (incallBgTask) {
		[[UIApplication sharedApplication]  endBackgroundTask:incallBgTask];
		incallBgTask=0;
	}
	
	/*IOS specific*/
	linphone_core_start_dtmf_stream(theLinphoneCore);

}

- (void)beginInterruption {
    LinphoneCall* c = linphone_core_get_current_call(theLinphoneCore);
    [LinphoneLogger logc:LinphoneLoggerLog format:"Sound interruption detected!"];
    if (c) {
        linphone_core_pause_call(theLinphoneCore, c);
    }
}

- (void)endInterruption {
    [LinphoneLogger logc:LinphoneLoggerLog format:"Sound interruption ended!"];
}

- (void)refreshRegisters{
	if (connectivity==none){
		//don't trust ios when he says there is no network. Create a new reachability context, the previous one might be mis-functionning.
		[self setupNetworkReachabilityCallback];
	}
	linphone_core_refresh_registers(theLinphoneCore);//just to make sure REGISTRATION is up to date
}


- (void)copyDefaultSettings {
    NSString *src = [LinphoneManager bundleFile:[LinphoneManager runningOnIpad]?@"linphonerc~ipad":@"linphonerc"];
    NSString *dst = [LinphoneManager documentFile:@".linphonerc"];
    [LinphoneManager copyFile:src destination:dst override:FALSE];
}


#pragma mark - Audio route Functions

- (bool)allowSpeaker {
    bool notallow = false;
    CFStringRef lNewRoute = CFSTR("Unknown");
    UInt32 lNewRouteSize = sizeof(lNewRoute);
    OSStatus lStatus = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &lNewRouteSize, &lNewRoute);
    if (!lStatus && lNewRouteSize > 0) {
        NSString *route = (NSString *) lNewRoute;
        notallow = [route isEqualToString: @"Headset"] ||
            [route isEqualToString: @"Headphone"] ||
            [route isEqualToString: @"HeadphonesAndMicrophone"] ||
            [route isEqualToString: @"HeadsetInOut"] ||
            [route isEqualToString: @"Lineout"];
        CFRelease(lNewRoute);
    }
    return !notallow;
}

static void audioRouteChangeListenerCallback (
                                              void                   *inUserData,                                 // 1
                                              AudioSessionPropertyID inPropertyID,                                // 2
                                              UInt32                 inPropertyValueSize,                         // 3
                                              const void             *inPropertyValue                             // 4
                                              ) {
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return; // 5
    LinphoneManager* lm = (LinphoneManager*)inUserData;
    
    bool speakerEnabled = false;
    CFStringRef lNewRoute = CFSTR("Unknown");
    UInt32 lNewRouteSize = sizeof(lNewRoute);
    OSStatus lStatus = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &lNewRouteSize, &lNewRoute);
    if (!lStatus && lNewRouteSize > 0) {
        NSString *route = (NSString *) lNewRoute;
        [LinphoneLogger logc:LinphoneLoggerLog format:"Current audio route is [%s]", [route cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        speakerEnabled = [route isEqualToString: @"Speaker"] || [route isEqualToString: @"SpeakerAndMicrophone"];
        if (![LinphoneManager runningOnIpad] && [route isEqualToString:@"HeadsetBT"] && !speakerEnabled) {
            lm.bluetoothEnabled = TRUE;
            lm.bluetoothAvailable = TRUE;
            NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:lm.bluetoothAvailable], @"available", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneBluetoothAvailabilityUpdate object:lm userInfo:dict];
        } else {
            lm.bluetoothEnabled = FALSE;
        }
        CFRelease(lNewRoute);
    }
    
    if(speakerEnabled != lm.speakerEnabled) { // Reforce value
        lm.speakerEnabled = lm.speakerEnabled;
    }
}

- (void)setSpeakerEnabled:(BOOL)enable {
    speakerEnabled = enable;

    if(enable && [self allowSpeaker]) {
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute
                                 , sizeof (audioRouteOverride)
                                 , &audioRouteOverride);
        bluetoothEnabled = FALSE;
    } else {
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute
                                 , sizeof (audioRouteOverride)
                                 , &audioRouteOverride);
    }

    if (bluetoothAvailable) {
        UInt32 bluetoothInputOverride = bluetoothEnabled;
        AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryEnableBluetoothInput, sizeof(bluetoothInputOverride), &bluetoothInputOverride);
    }
}

- (void)setBluetoothEnabled:(BOOL)enable {
    if (bluetoothAvailable) {
        // The change of route will be done in setSpeakerEnabled
        bluetoothEnabled = enable;
        if (bluetoothEnabled) {
            [self setSpeakerEnabled:FALSE];
        } else {
            [self setSpeakerEnabled:speakerEnabled];
        }
    }
}

#pragma mark - Call Functions

- (void)acceptCall:(LinphoneCall *)call {
    LinphoneCallParams* lcallParams = linphone_core_create_default_call_parameters(theLinphoneCore);
    if([self lpConfigBoolForKey:@"edge_opt_preference"]) {
        bool low_bandwidth = self.network == network_2g;
        if(low_bandwidth) {
            [LinphoneLogger log:LinphoneLoggerLog format:@"Low bandwidth mode"];
        }
        linphone_call_params_enable_low_bandwidth(lcallParams, low_bandwidth);
    }
    linphone_core_accept_call_with_params(theLinphoneCore,call, lcallParams);
}

- (void)call:(NSString *)address displayName:(NSString*)displayName transfer:(BOOL)transfer {
    if (!linphone_core_is_network_reachable(theLinphoneCore)) {
		UIAlertView* error = [[UIAlertView alloc]	initWithTitle:NSLocalizedString(@"Network Error",nil)
														message:NSLocalizedString(@"There is no network connection available, enable WIFI or WWAN prior to place a call",nil) 
													   delegate:nil 
											  cancelButtonTitle:NSLocalizedString(@"Continue",nil) 
											  otherButtonTitles:nil];
		[error show];
        [error release];
		return;
	}
    
    CTCallCenter* callCenter = [[CTCallCenter alloc] init];
    if ([callCenter currentCalls]!=nil) {
        [LinphoneLogger logc:LinphoneLoggerError format:"GSM call in progress, cancelling outgoing SIP call request"];
		UIAlertView* error = [[UIAlertView alloc]	initWithTitle:NSLocalizedString(@"Cannot make call",nil)
														message:NSLocalizedString(@"Please terminate GSM call",nil) 
													   delegate:nil 
											  cancelButtonTitle:NSLocalizedString(@"Continue",nil) 
											  otherButtonTitles:nil];
		[error show];
        [error release];
		[callCenter release];
		return;
    }
    [callCenter release];
	
	LinphoneProxyConfig* proxyCfg;	
	//get default proxy
	linphone_core_get_default_proxy(theLinphoneCore,&proxyCfg);
	LinphoneCallParams* lcallParams = linphone_core_create_default_call_parameters(theLinphoneCore);
    if([self lpConfigBoolForKey:@"edge_opt_preference"]) {
        bool low_bandwidth = self.network == network_2g;
        if(low_bandwidth) {
            [LinphoneLogger log:LinphoneLoggerLog format:@"Low bandwidth mode"];
        }
        linphone_call_params_enable_low_bandwidth(lcallParams, low_bandwidth);
    }
	LinphoneCall* call=NULL;
	
	if ([address length] == 0) return; //just return
	if ([address hasPrefix:@"sip:"]) {
        LinphoneAddress* linphoneAddress = linphone_address_new([address cStringUsingEncoding:[NSString defaultCStringEncoding]]);  
        if(displayName!=nil) {
            linphone_address_set_display_name(linphoneAddress,[displayName cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
        if ([[LinphoneManager instance] lpConfigBoolForKey:@"override_domain_with_default_one"])
            linphone_address_set_domain(linphoneAddress, [[[LinphoneManager instance] lpConfigStringForKey:@"domain" forSection:@"wizard"] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        if(transfer) {
            linphone_core_transfer_call(theLinphoneCore, linphone_core_get_current_call(theLinphoneCore), [address cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        } else {
            call=linphone_core_invite_address_with_params(theLinphoneCore, linphoneAddress, lcallParams);
        }
        linphone_address_destroy(linphoneAddress);
	} else if (proxyCfg==nil){
		UIAlertView* error = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid SIP address",nil)
														message:NSLocalizedString(@"Either configure a SIP proxy server from settings prior to place a call or use a valid SIP address (I.E sip:john@example.net)",nil)
													   delegate:nil 
											  cancelButtonTitle:NSLocalizedString(@"Continue",nil) 
											  otherButtonTitles:nil];
		[error show];
		[error release];
	} else {
		char normalizedUserName[256];
        LinphoneAddress* linphoneAddress = linphone_address_new(linphone_core_get_identity(theLinphoneCore));
		linphone_proxy_config_normalize_number(proxyCfg,[address cStringUsingEncoding:[NSString defaultCStringEncoding]],normalizedUserName,sizeof(normalizedUserName));
        linphone_address_set_username(linphoneAddress, normalizedUserName);
        if(displayName!=nil) {
            linphone_address_set_display_name(linphoneAddress, [displayName cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
        if ([[LinphoneManager instance] lpConfigBoolForKey:@"override_domain_with_default_one"])
            linphone_address_set_domain(linphoneAddress, [[[LinphoneManager instance] lpConfigStringForKey:@"domain" forSection:@"wizard"] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        if(transfer) {
            linphone_core_transfer_call(theLinphoneCore, linphone_core_get_current_call(theLinphoneCore), linphone_address_as_string_uri_only(linphoneAddress));
        } else {
            call=linphone_core_invite_address_with_params(theLinphoneCore, linphoneAddress, lcallParams);
        }
        linphone_address_destroy(linphoneAddress);
	}
	if (call) {
		LinphoneCallAppData* data = [[LinphoneCallAppData alloc] init];
        data->videoRequested = linphone_call_params_video_enabled(lcallParams); /* will be used later to notify user if video was not activated because of the linphone core*/
		linphone_call_set_user_pointer(call, data);
	}
	linphone_call_params_destroy(lcallParams);
}


#pragma mark - Property Functions

- (void)setPushNotificationToken:(NSData *)apushNotificationToken {
    if(apushNotificationToken == pushNotificationToken) {
        return;
    }
    if(pushNotificationToken != nil) {
        [pushNotificationToken release];
        pushNotificationToken = nil;
    }
    
    if(apushNotificationToken != nil) {
        pushNotificationToken = [apushNotificationToken retain];
    }
    if([LinphoneManager isLcReady]) {
		LinphoneProxyConfig *cfg=nil;
		linphone_core_get_default_proxy(theLinphoneCore, &cfg);
        if (cfg) {
			linphone_proxy_config_edit(cfg);
			[self addPushTokenToProxyConfig: cfg];
			linphone_proxy_config_done(cfg);
		}
    }
}

- (void)addPushTokenToProxyConfig:(LinphoneProxyConfig*)proxyCfg{
	NSData *tokenData =  pushNotificationToken;
	if(tokenData != nil && [self lpConfigBoolForKey:@"pushnotification_preference"]) {
		const unsigned char *tokenBuffer = [tokenData bytes];
		NSMutableString *tokenString = [NSMutableString stringWithCapacity:[tokenData length]*2];
		for(int i = 0; i < [tokenData length]; ++i) {
			[tokenString appendFormat:@"%02X", (unsigned int)tokenBuffer[i]];
		}
		// NSLocalizedString(@"IC_MSG", nil); // Fake for genstrings
		// NSLocalizedString(@"IM_MSG", nil); // Fake for genstrings
#ifdef DEBUG
#define APPMODE_SUFFIX @"dev"
#else
#define APPMODE_SUFFIX @"prod"
#endif
		NSString *params = [NSString stringWithFormat:@"app-id=%@.%@;pn-type=apple;pn-tok=%@;pn-msg-str=IM_MSG;pn-call-str=IC_MSG;pn-call-snd=ring.caf;pn-msg-snd=msg.caf", [[NSBundle mainBundle] bundleIdentifier],APPMODE_SUFFIX,tokenString];
		linphone_proxy_config_set_contact_parameters(proxyCfg, [params UTF8String]);
	}
}


#pragma mark - Misc Functions

+ (NSString*)bundleFile:(NSString*)file {
    return [[NSBundle mainBundle] pathForResource:[file stringByDeletingPathExtension] ofType:[file pathExtension]];
}

+ (NSString*)documentFile:(NSString*)file {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    return [documentsPath stringByAppendingPathComponent:file];
}

+ (BOOL)copyFile:(NSString*)src destination:(NSString*)dst override:(BOOL)override {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:dst] == YES) {
        if(override) {
            [fileManager removeItemAtPath:dst error:&error];
            if(error != nil) {
                [LinphoneLogger log:LinphoneLoggerError format:@"Can't remove \"%@\": %@", dst, [error localizedDescription]];
                return FALSE;
            }
        } else {
            [LinphoneLogger log:LinphoneLoggerWarning format:@"\"%@\" already exists", dst];
            return FALSE;
        }
    }
    if ([fileManager fileExistsAtPath:src] == NO) {
        [LinphoneLogger log:LinphoneLoggerError format:@"Can't find \"%@\": %@", src, [error localizedDescription]];
        return FALSE;
    }
    [fileManager copyItemAtPath:src toPath:dst error:&error];
    if(error != nil) {
        [LinphoneLogger log:LinphoneLoggerError format:@"Can't copy \"%@\" to \"%@\": %@", src, dst, [error localizedDescription]];
        return FALSE;
    }
    return TRUE;
}


#pragma mark - LPConfig Functions

- (void)lpConfigSetString:(NSString*)value forKey:(NSString*)key {
    [self lpConfigSetString:value forKey:key forSection:[NSString stringWithUTF8String:LINPHONERC_APPLICATION_KEY]];
}

- (void)lpConfigSetString:(NSString*)value forKey:(NSString*)key forSection:(NSString *)section {
	if (!key) return;
	lp_config_set_string(linphone_core_get_config(theLinphoneCore), [section UTF8String], [key UTF8String], value?[value UTF8String]:NULL);
}

- (NSString*)lpConfigStringForKey:(NSString*)key {
    return [self lpConfigStringForKey:key forSection:[NSString stringWithUTF8String:LINPHONERC_APPLICATION_KEY]];
}
- (NSString*)lpConfigStringForKey:(NSString*)key withDefault:(NSString*)defaultValue {
	NSString* value = [self lpConfigStringForKey:key];
	return value?value:defaultValue;
}

- (NSString*)lpConfigStringForKey:(NSString*)key forSection:(NSString *)section {
    if (!key) return nil;
	const char* value = lp_config_get_string(linphone_core_get_config(theLinphoneCore), [section UTF8String], [key UTF8String], NULL);
	if (value)
		return [NSString stringWithUTF8String:value];
	else
		return nil;
}

- (void)lpConfigSetInt:(NSInteger)value forKey:(NSString*)key {
    [self lpConfigSetInt:value forKey:key forSection:[NSString stringWithUTF8String:LINPHONERC_APPLICATION_KEY]];
}

- (void)lpConfigSetInt:(NSInteger)value forKey:(NSString*)key forSection:(NSString *)section {
    if (!key) return;
	lp_config_set_int(linphone_core_get_config(theLinphoneCore), [section UTF8String], [key UTF8String], value );
}

- (NSInteger)lpConfigIntForKey:(NSString*)key {
    return [self lpConfigIntForKey:key forSection:[NSString stringWithUTF8String:LINPHONERC_APPLICATION_KEY]];
}

- (NSInteger)lpConfigIntForKey:(NSString*)key forSection:(NSString *)section {
    if (!key) return -1;
	return lp_config_get_int(linphone_core_get_config(theLinphoneCore), [section UTF8String], [key UTF8String], -1);
}

- (void)lpConfigSetBool:(BOOL)value forKey:(NSString*)key {
    [self lpConfigSetBool:value forKey:key forSection:[NSString stringWithUTF8String:LINPHONERC_APPLICATION_KEY]];
}

- (void)lpConfigSetBool:(BOOL)value forKey:(NSString*)key forSection:(NSString *)section {
	return [self lpConfigSetInt:(NSInteger)(value == TRUE) forKey:key forSection:section];
}

- (BOOL)lpConfigBoolForKey:(NSString*)key {
    return [self lpConfigBoolForKey:key forSection:[NSString stringWithUTF8String:LINPHONERC_APPLICATION_KEY]];
}

- (BOOL)lpConfigBoolForKey:(NSString*)key forSection:(NSString *)section {
	return [self lpConfigIntForKey:key forSection:section] == 1;
}

#pragma GSM management
-(void) removeCTCallCenterCb {
	if (mCallCenter != nil) {
		[LinphoneLogger log:LinphoneLoggerLog format:@"Removing CT call center listener [%p]",mCallCenter];
		mCallCenter.callEventHandler=NULL;
		[mCallCenter release];
	}
	mCallCenter=nil;
}

- (void)setupGSMInteraction {
    
	[self removeCTCallCenterCb];
    mCallCenter = [[CTCallCenter alloc] init];
	[LinphoneLogger log:LinphoneLoggerLog format:@"Adding CT call center listener [%p]",mCallCenter];
    mCallCenter.callEventHandler = ^(CTCall* call) {
		// post on main thread
		[self performSelectorOnMainThread:@selector(handleGSMCallInteration:)
							   withObject:mCallCenter
							waitUntilDone:YES];
	};
    
}

- (void)handleGSMCallInteration: (id) cCenter {
    CTCallCenter* ct = (CTCallCenter*) cCenter;
	/* pause current call, if any */
	LinphoneCall* call = linphone_core_get_current_call(theLinphoneCore);
	if ([ct currentCalls]!=nil) {
		if (call) {
			[LinphoneLogger log:LinphoneLoggerLog format:@"Pausing SIP call because GSM call"];
			linphone_core_pause_call(theLinphoneCore, call);
			[self startCallPausedLongRunningTask];
		} else if (linphone_core_is_in_conference(theLinphoneCore)) {
			[LinphoneLogger log:LinphoneLoggerLog format:@"Leaving conference call because GSM call"];
			linphone_core_leave_conference(theLinphoneCore);
			[self startCallPausedLongRunningTask];
		}
	} //else nop, keep call in paused state
}
-(NSString*) contactFilter {
	NSString* filter=@"*";
	if ( [self lpConfigBoolForKey:@"contact_filter_on_default_domain"]) {
		LinphoneProxyConfig* proxy_cfg;
		linphone_core_get_default_proxy(theLinphoneCore, &proxy_cfg);
		if (proxy_cfg && linphone_proxy_config_get_addr(proxy_cfg)) {
			return [NSString stringWithCString:linphone_proxy_config_get_domain(proxy_cfg)
									  encoding:[NSString defaultCStringEncoding]];
		}
	}
	return filter;
}
@end
