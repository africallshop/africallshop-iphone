/* PhoneMainView.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
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

#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioServices.h>

#import "LinphoneAppDelegate.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import "DTActionSheet.h"

static PhoneMainView* phoneMainViewInstance=nil;

@implementation PhoneMainView

@synthesize mainViewController;
@synthesize currentView;


#pragma mark - Lifecycle Functions

- (void)initPhoneMainView {
    assert (!phoneMainViewInstance);
    phoneMainViewInstance = self;
    currentView = nil;
    viewStack = [[NSMutableArray alloc] init];
    loadCount = 0; // For avoiding IOS 4 bug
    inhibitedEvents = [[NSMutableArray alloc] init];
}

- (id)init {
    self = [super init];
    if (self) {
		[self initPhoneMainView];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		[self initPhoneMainView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
		[self initPhoneMainView];
	}
    return self;
}	

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [mainViewController release];
    [inhibitedEvents release];
    [viewStack release];

    [super dealloc];
}


#pragma mark - ViewController Functions

- (void)viewDidLoad {
    // Avoid IOS 4 bug
    if(loadCount++ > 0)
        return;
    
    [super viewDidLoad];

    [self.view addSubview: mainViewController.view];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [mainViewController viewWillAppear:animated];
    }   
    
    // Set observers
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(callUpdate:) 
                                                 name:kLinphoneCallUpdate
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(registrationUpdate:) 
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(textReceived:) 
                                                 name:kLinphoneTextReceived
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(batteryLevelChanged:) 
                                                 name:UIDeviceBatteryLevelDidChangeNotification
                                               object:nil];
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    
    batteryTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(batteryLevelChanged:) userInfo:nil repeats:TRUE];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [mainViewController viewWillDisappear:animated];
    }
    
    // Remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                 name:kLinphoneCallUpdate
                                               object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                 name:kLinphoneRegistrationUpdate
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                 name:kLinphoneTextReceived
                                               object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                 name:UIDeviceBatteryLevelDidChangeNotification 
                                               object:nil];
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:NO];
    
    [batteryTimer invalidate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [mainViewController viewDidAppear:animated];
    }   
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [mainViewController viewDidDisappear:animated];
    }  
}

- (void)viewDidUnload {
    [super viewDidUnload];

    // Avoid IOS 4 bug
    loadCount--;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if(interfaceOrientation == self.interfaceOrientation)
        return YES;
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return 0;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [mainViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self orientationUpdate:toInterfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [mainViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [mainViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (UIInterfaceOrientation)interfaceOrientation {
    return [mainViewController currentOrientation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [mainViewController clearCache:viewStack];
}

#pragma mark - Event Functions

- (void)textReceived:(NSNotification*)notif { 
    ChatModel *chat = [[notif userInfo] objectForKey:@"chat"];
    if(chat != nil) {
        [self displayMessage:chat];
    }
    [self updateApplicationBadgeNumber];
}

- (void)registrationUpdate:(NSNotification*)notif {
    LinphoneRegistrationState state = [[notif.userInfo objectForKey: @"state"] intValue];
    LinphoneProxyConfig *cfg = [[notif.userInfo objectForKey: @"cfg"] pointerValue];
	//Only report bad credential issue
    if (state == LinphoneRegistrationFailed
		&&[UIApplication sharedApplication].applicationState != UIApplicationStateBackground
		&& linphone_proxy_config_get_error(cfg) == LinphoneReasonBadCredentials ) {
		UIAlertView* error = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Registration failure",nil)
														message:NSLocalizedString(@"Bad credentials, check your account settings", nil)
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
											  otherButtonTitles:nil,nil];
		[error show];
		[error release];
	}
}

- (void)callUpdate:(NSNotification*)notif {
    LinphoneCall *call = [[notif.userInfo objectForKey: @"call"] pointerValue];
    LinphoneCallState state = [[notif.userInfo objectForKey: @"state"] intValue];
    NSString *message = [notif.userInfo objectForKey: @"message"];
    
    bool canHideInCallView = (linphone_core_get_calls([LinphoneManager getLc]) == NULL);
    
    // Don't handle call state during incoming call view
    if([[self currentView] equal:[IncomingCallViewController compositeViewDescription]] && state != LinphoneCallError && state != LinphoneCallEnd) {
        return;
    }
    
	switch (state) {					
		case LinphoneCallIncomingReceived: 
        {
			[self displayIncomingCall:call];
			break;
        }
		case LinphoneCallOutgoingInit: 
        case LinphoneCallPausedByRemote:
		case LinphoneCallConnected:
        case LinphoneCallStreamsRunning:
        {
            [self changeCurrentView:[InCallViewController compositeViewDescription]];
            break;
        }
        case LinphoneCallUpdatedByRemote:
        {
            const LinphoneCallParams* current = linphone_call_get_current_params(call);
            const LinphoneCallParams* remote = linphone_call_get_remote_params(call);
            
            if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
                [self changeCurrentView:[InCallViewController compositeViewDescription]];
            }
            break;
        }
		case LinphoneCallError:
        {
            [self displayCallError:call message: message];
        }
		case LinphoneCallEnd: 
        {
            if (canHideInCallView) {
                // Go to dialer view
                DialerViewController *controller = DYNAMIC_CAST([self changeCurrentView:[DialerViewController compositeViewDescription]], DialerViewController);
                if(controller != nil) {
                    [controller setAddress:@""];
                    [controller setTransferMode:FALSE];
                }
            } else {
                [self changeCurrentView:[InCallViewController compositeViewDescription]];
			}
			break;
        }
        default:
            break;
	}
    [self updateApplicationBadgeNumber];
}


#pragma mark - 

- (void)orientationUpdate:(UIInterfaceOrientation)orientation {
    int oldLinphoneOrientation = linphone_core_get_device_rotation([LinphoneManager getLc]);
    int newRotation = 0;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            newRotation = 0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            newRotation = 180;
            break;
        case UIInterfaceOrientationLandscapeRight:
            newRotation = 270;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            newRotation = 90;
            break;
        default:
            newRotation = oldLinphoneOrientation;
    }
    if (oldLinphoneOrientation != newRotation) {
        linphone_core_set_device_rotation([LinphoneManager getLc], newRotation);
        LinphoneCall* call = linphone_core_get_current_call([LinphoneManager getLc]);
        if (call && linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
            //Orientation has changed, must call update call
            linphone_core_update_call([LinphoneManager getLc], call, NULL);
        }
    }
}

- (void)startUp {   
    if ([[LinphoneManager instance] lpConfigBoolForKey:@"enable_first_login_view_preference"]  == true) {
        // Change to fist login view
        [self changeCurrentView: [FirstLoginViewController compositeViewDescription]];
    } else {
        // Change to default view
        const MSList *list = linphone_core_get_proxy_config_list([LinphoneManager getLc]);
        if(list != NULL || ([[LinphoneManager instance] lpConfigBoolForKey:@"hide_wizard_preference"]  == true)) {
            [self changeCurrentView: [DialerViewController compositeViewDescription]];
        } else {
            WizardViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[WizardViewController compositeViewDescription]], WizardViewController);
            if(controller != nil) {
                [controller reset];
            }
        }
    }
    
    [self updateApplicationBadgeNumber]; // Update Badge at startup
}

- (void)updateApplicationBadgeNumber {
    int count = 0;
    count += linphone_core_get_missed_calls_count([LinphoneManager getLc]);
    count += [ChatModel unreadMessages];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
}

+ (CATransition*)getBackwardTransition {
    CATransition* trans = [CATransition animation];
    [trans setType:kCATransitionPush];
    [trans setDuration:0.35];
    [trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [trans setSubtype:kCATransitionFromLeft];
    
    return trans;
}

+ (CATransition*)getForwardTransition {
    CATransition* trans = [CATransition animation];
    [trans setType:kCATransitionPush];
    [trans setDuration:0.35];
    [trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [trans setSubtype:kCATransitionFromRight];
    
    return trans;
}

+ (CATransition*)getTransition:(UICompositeViewDescription *)old new:(UICompositeViewDescription *)new {
    bool left = false;
    
    if([old equal:[ChatViewController compositeViewDescription]]) {
        if([new equal:[ContactsViewController compositeViewDescription]] ||
           [new equal:[DialerViewController   compositeViewDescription]] ||
           [new equal:[HistoryViewController  compositeViewDescription]]) {
            left = true;
        }
    } else if([old equal:[SettingsViewController compositeViewDescription]]) {
        if([new equal:[DialerViewController   compositeViewDescription]] ||
           [new equal:[ContactsViewController compositeViewDescription]] ||
           [new equal:[HistoryViewController  compositeViewDescription]] ||
           [new equal:[ChatViewController     compositeViewDescription]]) {
            left = true;
        }
    } else if([old equal:[DialerViewController compositeViewDescription]]) {
        if([new equal:[ContactsViewController  compositeViewDescription]] ||
           [new equal:[HistoryViewController   compositeViewDescription]]) {
            left = true;
        }
    } else if([old equal:[ContactsViewController compositeViewDescription]]) {
        if([new equal:[HistoryViewController compositeViewDescription]]) {
            left = true;
        }
    } 
    
    if(left) {
        return [PhoneMainView getBackwardTransition];
    } else {
        return [PhoneMainView getForwardTransition];
    }
}

+ (PhoneMainView *) instance {
    return phoneMainViewInstance;
}

- (void) showTabBar:(BOOL)show {
    [mainViewController setToolBarHidden:!show];
}

- (void) showStateBar:(BOOL)show {
    [mainViewController setStateBarHidden:!show];
}

- (void)updateStatusBar:(UICompositeViewDescription*)to_view {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([LinphoneManager runningOnIpad]) {
        // In iOS7, the ipad has a black background on dialer, so we have to adjust the
        // status bar style for each transition to/from this view
        BOOL toLightStatus   = [to_view     equal:[DialerViewController compositeViewDescription]];
        BOOL fromLightStatus = [currentView equal:[DialerViewController compositeViewDescription]];
        if( (!to_view && fromLightStatus) || // this case happens at app launch
            toLightStatus )
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        else if(fromLightStatus)
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    }
#endif
}


- (void)fullScreen:(BOOL)enabled {
    [mainViewController setFullScreen:enabled];
}

- (UIViewController*)changeCurrentView:(UICompositeViewDescription *)view {
    return [self changeCurrentView:view push:FALSE];
}

- (UIViewController*)changeCurrentView:(UICompositeViewDescription*)view push:(BOOL)push {
    BOOL force = push;
    if(!push) {
        force = [viewStack count] > 1;
        [viewStack removeAllObjects];
    }
    [viewStack addObject:view];
    return [self _changeCurrentView:view transition:nil force:force];
}

- (UIViewController*)_changeCurrentView:(UICompositeViewDescription*)view transition:(CATransition*)transition force:(BOOL)force {
    [LinphoneLogger logc:LinphoneLoggerLog format:"PhoneMainView: Change current view to %@", [view name]];
    
    if(force || ![view equal: currentView]) {
        if(transition == nil)
            transition = [PhoneMainView getTransition:currentView new:view];
        if ([[LinphoneManager instance] lpConfigBoolForKey:@"animations_preference"] == true) {
            [mainViewController setViewTransition:transition];
        } else {
            [mainViewController setViewTransition:nil];
        }
        [self updateStatusBar:view];
        [mainViewController changeView:view];
        currentView = view;
    }
    
    NSDictionary* mdict = [NSMutableDictionary dictionaryWithObject:currentView forKey:@"view"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneMainViewChange object:self userInfo:mdict];
    
    return [mainViewController getCurrentViewController];
}

- (void)popToView:(UICompositeViewDescription*)view {
    while([viewStack count] > 1 && ![[viewStack lastObject] equal:view]) {
        [viewStack removeLastObject];
    }
    [self _changeCurrentView:[viewStack lastObject] transition:[PhoneMainView getBackwardTransition] force:TRUE];
}

- (UICompositeViewDescription *)firstView {
    UICompositeViewDescription *view = nil;
    if([viewStack count]) {
        view = [viewStack objectAtIndex:0];
    }
    return view;
}
         
- (UIViewController*)popCurrentView {
    [LinphoneLogger logc:LinphoneLoggerLog format:"PhoneMainView: Pop view"];
    if([viewStack count] > 1) {
        [viewStack removeLastObject];
        [self _changeCurrentView:[viewStack lastObject] transition:[PhoneMainView getBackwardTransition] force:TRUE];
        return [mainViewController getCurrentViewController];
    } 
    return nil;
}

- (void)displayCallError:(LinphoneCall*) call message:(NSString*) message {
    const char* lUserNameChars=linphone_address_get_username(linphone_call_get_remote_address(call));
    NSString* lUserName = lUserNameChars?[[[NSString alloc] initWithUTF8String:lUserNameChars] autorelease]:NSLocalizedString(@"Unknown",nil);
    NSString* lMessage;
    NSString* lTitle;
    
    //get default proxy
    LinphoneProxyConfig* proxyCfg;	
    linphone_core_get_default_proxy([LinphoneManager getLc],&proxyCfg);
    if (proxyCfg == nil) {
        lMessage = NSLocalizedString(@"Please make sure your device is connected to the internet and double check your SIP account configuration in the settings.", nil);
    } else {
        lMessage = [NSString stringWithFormat : NSLocalizedString(@"Cannot call %@", nil), lUserName];
    }
    
    if (linphone_call_get_reason(call) == LinphoneReasonNotFound) {
        lMessage = [NSString stringWithFormat : NSLocalizedString(@"'%@' not registered", nil), lUserName];
    } else {
        if (message != nil) {
            lMessage = [NSString stringWithFormat : NSLocalizedString(@"%@\nReason was: %@", nil), lMessage, message];
        }
    }
    lTitle = NSLocalizedString(@"Call failed",nil);
    UIAlertView* error = [[UIAlertView alloc] initWithTitle:lTitle
                                                    message:lMessage 
                                                   delegate:nil 
                                          cancelButtonTitle:NSLocalizedString(@"Dismiss",nil) 
                                          otherButtonTitles:nil];
    [error show];
    [error release];
}

- (void)addInhibitedEvent:(id)event {
    [inhibitedEvents addObject:event];
}

- (BOOL)removeInhibitedEvent:(id)event {
    NSUInteger index = [inhibitedEvents indexOfObject:event];
    if(index != NSNotFound) {
        [inhibitedEvents removeObjectAtIndex:index];
        return TRUE;
    }
    return FALSE;
}

#pragma mark - ActionSheet Functions

- (void)displayMessage:(ChatModel*)chat {
    if (![[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
		|| [UIApplication sharedApplication].applicationState ==  UIApplicationStateActive) {
        if(![self removeInhibitedEvent:kLinphoneTextReceived]) {
            AudioServicesPlaySystemSound([LinphoneManager instance].sounds.message);
        }
    }
}

- (void)displayIncomingCall:(LinphoneCall*) call{
 	LinphoneCallLog* callLog=linphone_call_get_call_log(call);
	NSString* callId=[NSString stringWithUTF8String:linphone_call_log_get_call_id(callLog)];

	if (![[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
		|| [UIApplication sharedApplication].applicationState ==  UIApplicationStateActive) {
		if ([[LinphoneManager instance] shouldAutoAcceptCallForCallId:callId]){
            [[LinphoneManager instance] acceptCall:call];
		}else{
			IncomingCallViewController *controller = DYNAMIC_CAST([self changeCurrentView:[IncomingCallViewController compositeViewDescription] push:TRUE],IncomingCallViewController);
			if(controller != nil) {
				[controller setCall:call];
				[controller setDelegate:self];
			}
		}
	}
}

- (void)batteryLevelChanged:(NSNotification*)notif {
    float level = [UIDevice currentDevice].batteryLevel;
    UIDeviceBatteryState state = [UIDevice currentDevice].batteryState;
    [LinphoneLogger log:LinphoneLoggerLog format:@"Battery state:%d level:%.2f", state, level];
    
	if (![LinphoneManager isLcReady]) return;
    LinphoneCall* call = linphone_core_get_current_call([LinphoneManager getLc]);
    if (call && linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
        LinphoneCallAppData* callData = (LinphoneCallAppData*) linphone_call_get_user_pointer(call);
        if(callData != nil) {
            if (state == UIDeviceBatteryStateUnplugged) {
                if (level <= 0.2f && !callData->batteryWarningShown) {
                    [LinphoneLogger log:LinphoneLoggerLog format:@"Battery warning"];
                    DTActionSheet *sheet = [[[DTActionSheet alloc] initWithTitle:NSLocalizedString(@"Battery is running low. Stop video ?",nil)] autorelease];
                    [sheet addCancelButtonWithTitle:NSLocalizedString(@"Continue video", nil) block:nil];
                    [sheet addDestructiveButtonWithTitle:NSLocalizedString(@"Stop video", nil) block:^() {
                        LinphoneCallParams* paramsCopy = linphone_call_params_copy(linphone_call_get_current_params(call));
                        // stop video
                        linphone_call_params_enable_video(paramsCopy, FALSE);
                        linphone_core_update_call([LinphoneManager getLc], call, paramsCopy);
                    }];
                    [sheet showInView:self.view];
                    callData->batteryWarningShown = TRUE;
                }
            }
            if (level > 0.2f) {
                callData->batteryWarningShown = FALSE;
            }
        }
    }
}


#pragma mark - IncomingCallDelegate Functions

- (void)incomingCallAborted:(LinphoneCall*)call {
}

- (void)incomingCallAccepted:(LinphoneCall*)call {
    [[LinphoneManager instance] acceptCall:call];
}

- (void)incomingCallDeclined:(LinphoneCall*)call {
    linphone_core_terminate_call([LinphoneManager getLc], call);
}

@end