/* ChatTableViewController.m
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

#import "ChatTableViewController.h"
#import "UIChatCell.h"

#import "linphonecore.h"
#import "PhoneMainView.h"
#import "UACellBackgroundView.h"
#import "UILinphone.h"
#import "Utils.h"

@implementation ChatTableViewController


#pragma mark - Lifecycle Functions

- (void)dealloc {
    if(data != nil)
        [data release];
    [super dealloc];
}


#pragma mark - ViewController Functions 

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadData];
}


#pragma mark - 

- (void)loadData {
    if(data != nil)
        [data release];
    
    [ChatModel deleteAll];
    
    //Get sms lists
    LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
    UserAccount *afriCallUserBal= [[UserAccount alloc] init];
    afriCallUserBal.email = appDelegate.afriCallUser.email;
    afriCallUserBal.firsPasswd=appDelegate.afriCallUser.firsPasswd;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *email=[defaults objectForKey:@"email"];
    NSString *firsPasswd=[defaults objectForKey:@"firsPasswd"];
    afriCallUserBal.email =email;
    afriCallUserBal.firsPasswd=firsPasswd;
    NSString *post =[[NSString alloc] initWithFormat:@"login=%@&password=%@",email,firsPasswd];
    NSLog(@"PostData: %@",post);
    
    NSURL *url=[NSURL URLWithString:@"https://www.africallshop.com/api/get_sms_ios.php"];
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *response = nil;
    NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSLog(@"Response code: %d", [response statusCode]);
    if ([response statusCode] >=200 && [response statusCode] <300)
    {
        NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
        
        NSLog(@"Response ==> %@", responseData);
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
        NSLog(@"%@",jsonData);
        
        for ( NSDictionary* dic in jsonData)
        {
            //Save message in database
            ChatModel *chat = [[ChatModel alloc] init];
            if ([dic objectForKey:@"destination"])
                [chat setRemoteContact:[dic objectForKey:@"destination"]];
            else
                [chat setRemoteContact:@""];
            
            if ([dic objectForKey:@"contenu"]!= (NSString *)[NSNull null])
                [chat setMessage:[dic objectForKey:@"contenu"]];
            else
                [chat setMessage:@""];
            
            
            [chat setLocalContact:@""];
            [chat setDirection:[NSNumber numberWithInt:0]];
            
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSDate *myDateGame = [df dateFromString:[dic objectForKey:@"date_envoi"]];
            
            [chat setTime:myDateGame];
            [chat setRead:[NSNumber numberWithInt:1]];
            [chat setState:[NSNumber numberWithInt:2]]; //INPROGRESS
            [chat create];
            [chat release];
        }
        
    }

    data = [[ChatModel listConversations] retain];
    [[self tableView] reloadData];
}

#pragma mark - UITableViewDataSource Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellId = @"UIChatCell";
    UIChatCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
    if (cell == nil) {
        cell = [[[UIChatCell alloc] initWithIdentifier:kCellId] autorelease];
        
        
        // Background View
        UACellBackgroundView *selectedBackgroundView = [[[UACellBackgroundView alloc] initWithFrame:CGRectZero] autorelease];
        cell.selectedBackgroundView = selectedBackgroundView;
        [selectedBackgroundView setBackgroundColor:LINPHONE_TABLE_CELL_BACKGROUND_COLOR];
    }
    
    [cell setChat:[data objectAtIndex:[indexPath row]]];
    
    return cell;
}


#pragma mark - UITableViewDelegate Functions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    ChatModel *chat = [data objectAtIndex:[indexPath row]];
    
    // Go to ChatRoom view
    ChatRoomViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE], ChatRoomViewController);
    if(controller != nil) {
        [controller setRemoteAddress:[chat remoteContact]];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Detemine if it's in editing mode
    if (self.editing) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath  {
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];
        ChatModel *chat = [data objectAtIndex:[indexPath row]];
        [ChatModel removeConversation:[chat remoteContact]];
        [data removeObjectAtIndex:[indexPath row]];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneTextReceived object:self];
    }
}

@end
