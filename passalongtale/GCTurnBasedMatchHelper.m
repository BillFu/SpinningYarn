//
//  GCTurnBasedMatchHelper.m
//  spinningyarn
//
//  Created by Bill Fu on 13-10-28.
//
//

#import "GCTurnBasedMatchHelper.h"

@implementation GCTurnBasedMatchHelper

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
        else if ([GKLocalPlayer localPlayer].isAuthenticated)
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
            NSLog(@"Local Player ID: %@", [GKLocalPlayer localPlayer].playerID);

            [[GKLocalPlayer localPlayer] registerListener:self];
            [self.delegate authenticationChanged:YES];
        }
        else
        {
            //If the authentication process failed
            [self.delegate authenticationChanged:NO];
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
        [self.delegate enterNewGame:match];

    }
    else
    {
        //NSLog(@"entered an existing Match");
        if ([match.currentParticipant.playerID
             isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // It's your turn!
            [self.delegate takeTurn:match];
        }
        else
        {
            // It's not your turn, just display the game state.
            [self.delegate layoutMatch:match];
        }
    }
}

-(void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController
                      playerQuitForMatch:(GKTurnBasedMatch *)match
{
    /*
    //除了playerQuit方法外，其他方法都会移除view controller并打印一些信息。
    //这是因为玩家在退出游戏时也许还想在这个界面做其他事情。
    NSLog(@"player QUIT from Match, %@, %@",
          match, match.currentParticipant);
    */
    
    NSUInteger currentPlayerIndex =
        [match.participants indexOfObject:match.currentParticipant];
    
    //local player has became DEAD, we should find next LIVE player and hand turn over to him.
    GKTurnBasedParticipant *livePlayer;
    for (int i = 0; i < [match.participants count]; i++)
    {
        livePlayer = [match.participants objectAtIndex:
                (currentPlayerIndex + 1 + i) % match.participants.count];
        if (livePlayer.matchOutcome != GKTurnBasedMatchOutcomeQuit)
        {
            break;
        }
    }
    
    if (livePlayer == nil) 
        return;
    
    NSArray* livePlayers = [[NSArray alloc] initWithObjects:livePlayer,nil];
     
    NSLog(@"player quit for Match, %@, %@", match, match.currentParticipant);
    
    [match participantQuitInTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                           nextParticipants:livePlayers
                                turnTimeout:GKTurnTimeoutDefault
                                  matchData:match.matchData
                          completionHandler:nil];
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

#pragma mark methods declared in the Protocol of GKLocalPlayerListener

//Handling Exchanges
- (void)player:(GKPlayer *)player
receivedExchangeCancellation:(GKTurnBasedExchange *)exchange
      forMatch:(GKTurnBasedMatch *)match
{
}

- (void)player:(GKPlayer *)player
receivedExchangeReplies:(NSArray *)replies
forCompletedExchange:(GKTurnBasedExchange *)exchange
      forMatch:(GKTurnBasedMatch *)match
{
}

- (void)player:(GKPlayer *)player
receivedExchangeRequest:(GKTurnBasedExchange *)exchange
      forMatch:(GKTurnBasedMatch *)match
{
}
//----Handling Match Related Events----
//see 506.pdf doucument
- (void)player:(GKPlayer *)player
receivedTurnEventForMatch:(GKTurnBasedMatch *)match
didBecomeActive:(BOOL)didBecomeActive
{
    // This event activated the application. This means that the user
    // tapped on the notification banner and wants to see or play this
    // match now.
    if (didBecomeActive)
    {
        // ??? [self switchToMatch:match];
        NSLog(@"return from didBecomeActive branch in receivedTurnEventForMatch");
        return;  //Notice here
    }
    
    
    NSLog(@"run second part from in receivedTurnEventForMatch");

    //Match updated
    // Handle the event more selectively
    if ([match.matchID isEqualToString:self.currentMatch.matchID])
    {
        // This is the match the user is currently playing,
        // update to show the latest state
        // ??? [self refreshMatch:match];
        if ([match.currentParticipant.playerID
             isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // it's the current match and it's our turn now
            self.currentMatch = match;
            [self.delegate takeTurn:match];
        }
        else
        {
            // it's the current match, but it's someone else's turn
            self.currentMatch = match;
            [self.delegate layoutMatch:match];
        }
    }
    else  //Turn received for different match
    {
        // It became the player’s turn in a different match
        if ([match.currentParticipant.playerID
             isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // it's not the current match and it's our turn now
            [self.delegate sendNotice:@"It's your turn for another match"
                        forMatch:match];
        }
        else
        {
            // it's the not current match, and it's someone else's
            // turn
        }
    }
}

/*
// Triggered by the user choosing to play with a friend from Game Center
- (void)player: (GKPlayer *)player
didRequestMatchWithPlayers: (NSArray *)playerIDsToInvite
{
    // Set up match request
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 2;
    request.playersToInvite = playerIDsToInvite;
    request.inviteMessage = @”Let’s play”;
    // Use the request to find or create a new match
    [GKTurnBasedMatch findMatchForRequest: request
                    withCompletionHandler: ^(GKTurnBasedMatch *match,
                                             NSError *error) { ... }];
}
*/

- (void)player:(GKPlayer *)player
didRequestMatchWithPlayers:(NSArray *)playerIDsToInvite
{
    
}

- (void)player:(GKPlayer *)player
    matchEnded:(GKTurnBasedMatch *)match
{
    
}
@end
