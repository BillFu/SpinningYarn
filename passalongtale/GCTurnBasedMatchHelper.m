//
//  GCTurnBasedMatchHelper.m
//  spinningyarn
//
//  Created by Bill Fu on 13-10-28.
//
//

#import "GCTurnBasedMatchHelper.h"

@interface GCTurnBasedMatchHelper()
{
    UIViewController *presentingViewController;
}
@end

@implementation GCTurnBasedMatchHelper

@synthesize currentMatch;
@synthesize delegate;

#pragma mark Initialization

static GCTurnBasedMatchHelper *sharedHelper = nil;
+ (GCTurnBasedMatchHelper *) sharedInstance
{
    if (!sharedHelper)
    {
        sharedHelper = [[GCTurnBasedMatchHelper alloc] init];
    }
    return sharedHelper;
}

#pragma mark User functions

- (void)authenticationChanged
{
    
}
/*
 Once you set an authentication handler, Game Kit automatically authenticates
 the player asynchronously, calling your authentication handler as necessary to complete the process.Each
 time your game moves from the background to the foreground, Game Kit automatically authenticates the
 local player again.
 */
- (void)authenticateLocalUser
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
/*
 Once you set an authentication handler, Game Kit automatically authenticates
 the player asynchronously, calling your authentication handler as necessary to complete the process. Each
 time your game moves from the background to the foreground, Game Kit automatically authenticates the
 local player again.
 */
    localPlayer.authenticateHandler = ^(UIViewController *viewController,
                                        NSError *error)
    {
        [self setLastError:error];
        
        if (viewController != nil)
        {
/*
 If the device does not have an authenticated player, Game Kit passes a view controller to your authentication
 handler. When presented by your game, this view controller displays the authentication user interface.
 Soon after, your game should pause other activities that require user interaction and present this view
 controller. Game Kit dismisses this view controller automatically when complete, and calls your
 authentication handler again.
 */
            //showAuthenticationDialogWhenReasonable: is an example method name.
            //Create your own method that displays an authentication view when appropriate for
            //    your app.
            [self presentViewController:viewController];
        }
        else if (localPlayer.isAuthenticated)
        {
            //If the authentication process succeeded,
            //authenticatedPlayer: is an example method name. Create your own
            //method that is called after the loacal player is authenticated.
            /*
            [GKTurnBasedMatch loadMatchesWithCompletionHandler:
                    ^(NSArray *matches, NSError *error)
                {
                     for (GKTurnBasedMatch *match in matches)
                     {
                         NSLog(@"remove existed match %@", match.matchID);
                         [match removeWithCompletionHandler:^(NSError *error){
                             NSLog(@"%@", error);}];
                     }
                }
             ];
            */
            //[self authenticatedPlayer: localPlayer];
        }
        else
        {
            //If the authentication process failed
            //[self disableGameCenter];
        }
    };
    
}

#pragma mark Property setters

-(void) setLastError:(NSError*)error
{
    _lastError = [error copy];
    if (_lastError)
    {
        NSLog(@"GameKitHelper ERROR: %@", [[_lastError userInfo]
                                           description]);
    }
}

#pragma mark UIViewController stuff

-(UIViewController*) getRootViewController
{
    return [UIApplication
            sharedApplication].keyWindow.rootViewController;
}

-(void)presentViewController:(UIViewController*)vc
{
    UIViewController* rootVC = [self getRootViewController];
    [rootVC presentViewController:vc
                         animated:YES
                       completion:nil];
}

- (void)findMatchWithMinPlayers:(int)minPlayers
                     maxPlayers:(int)maxPlayers
                 viewController:(UIViewController *)viewController
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    if(localPlayer.isAuthenticated == NO)
    {
        NSLog(@"localPlayer NOT anthenticated in findMatchWithMinPlayers()");
        return;
    }
    
    presentingViewController = viewController;
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = minPlayers;
    request.maxPlayers = maxPlayers;
    
    GKTurnBasedMatchmakerViewController *mmvc =
            [[GKTurnBasedMatchmakerViewController alloc]
             initWithMatchRequest:request];
    mmvc.turnBasedMatchmakerDelegate = self;
    mmvc.showExistingMatches = YES;
    
    [presentingViewController presentViewController:mmvc
                                           animated:YES
                                         completion:nil];
}

#pragma mark methods declared in GKTurnBasedMatchmakerViewControllerDelegate

- (void)turnBasedMatchmakerViewControllerWasCancelled:
                    (GKTurnBasedMatchmakerViewController*)viewController
{
    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"User hit Cancel or Done button when MMVC is presented");
}

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController*)viewController
                         didFailWithError:(NSError *)error
{
    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"Error when finding match: %@", error.localizedDescription);
}

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController*)viewController
                             didFindMatch:(GKTurnBasedMatch *)match
{
    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
    //[presentingViewController performSegueWithIdentifier:@"GamePlayScene" sender:match];
    
    self.currentMatch = match;
    
    GKTurnBasedParticipant *firstParticipant =
        [match.participants objectAtIndex:0];
    if (firstParticipant.lastTurnDate == nil)
    {
        //NSLog(@"new Match started");
        [delegate enterNewGame:match];

    }
    else
    {
        //NSLog(@"entered an existing Match");
        if ([match.currentParticipant.playerID
             isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // It's your turn!
            [delegate takeTurn:match];
        }
        else
        {
            // It's not your turn, just display the game state.
            [delegate layoutMatch:match];
        }
    }
}

-(void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController
                      playerQuitForMatch:(GKTurnBasedMatch *)match
{
    //除了playerQuit方法外，其他方法都会移除view controller并打印一些信息。
    //这是因为玩家在退出游戏时也许还想在这个界面做其他事情。
    NSLog(@"player QUIT from Match, %@, %@",
          match, match.currentParticipant);
}

/*
 - (void )prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 if ([segue.identifier isEqualToString:@"GamePlayScene"])
 {
 MyGamePlayViewController* gameVC = (MyGamePlayViewController*)
 segue.destinationViewController;
 gameVC.delegate = self;
 gameVC.match = (GKTurnBasedMatch*) sender;
 }
 }
 */
@end
