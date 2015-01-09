//
//  myWebViewController.m
//  linphone
//
//  Created by Abdel Karim on 23/11/13.
//
//

#import "myWebViewController.h"

@interface myWebViewController ()

@end

@implementation myWebViewController
@synthesize licensesView;
@synthesize contentView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // Create a request to the resource
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:@"https://www.africallshop.com/api/add_solde.php?login=karimjimo@yahoo.fr&password=motdepasseaf"]] ;
    // Load the resource using the request
    [licensesView setDelegate:self];
    [licensesView loadRequest:request];
    [[myWebViewController defaultScrollView:licensesView] setScrollEnabled:FALSE];
}
+ (UIScrollView *)defaultScrollView:(UIWebView *)webView {
    UIScrollView *scrollView = nil;
    
    if ([[UIDevice currentDevice].systemVersion doubleValue] >= 5.0) {
        return webView.scrollView;
    }  else {
        for (UIView *subview in [webView subviews]) {
            if ([subview isKindOfClass:[UIScrollView class]]) {
                scrollView = (UIScrollView *)subview;
            }
        }
    }
    return scrollView;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - UIWebViewDelegate Functions

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    CGSize size = [webView sizeThatFits:CGSizeMake(self.view.bounds.size.width, 10000.0f)];
    float diff = size.height - webView.bounds.size.height;
    
    UIScrollView *scrollView = (UIScrollView *)self.view;
    CGRect contentFrame = [contentView bounds];
    contentFrame.size.height += diff;
    [contentView setAutoresizesSubviews:FALSE];
    [contentView setFrame:contentFrame];
    [contentView setAutoresizesSubviews:TRUE];
    [scrollView setContentSize:contentFrame.size];
    CGRect licensesViewFrame = [licensesView frame];
    licensesViewFrame.size.height += diff;
    [licensesView setFrame:licensesViewFrame];
}

- (BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if (inType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

@end
