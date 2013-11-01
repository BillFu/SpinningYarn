//
//  GCTurnBasedMatchHelper.h
//  spinningyarn
//
//  Created by Bill Fu on 13-10-28.
//
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@protocol GCTurnBasedMatchHelperDelegate

- (void)authenticationChanged:(BOOL)successFlag;

/*
 当通过didFindMatch方法弹出一个新游戏时，我们想在屏幕显示一个“Once upon a time”的初始字符串。
 */
- (void)enterNewGame:(GKTurnBasedMatch *)match;

/*
 layoutMatch方法当我们想要观看一个其他玩家回合的比赛时调用（例如仅仅查看当前比赛中故事的状态）。
 在这种情况下，我们将要防止玩家发送一个回合，但是仍需要更新UI来反映出当前比赛的状态。
 The layoutMatch method is used when we want to view a match where it’s another player’s turn (just to check the state of the story for example). We want to prevent the player from sending a turn in this case, but we still want to update the UI to reflect the most current state of the match.
 */
- (void)layoutMatch:(GKTurnBasedMatch *)match;

/*
 takeTurn方法是当玩家的回合时被调用，但它是一个已经存在的比赛。
 这种情况适用于当玩家从GKTurnBasedMatchmakerViewController选择了一个已经存在的比赛，
 或者一个新的回合notification进入时。
 The takeTurn method is for those cases when it is our player’s turn, but it’s an existing match. 
    This scenario exists when our player chooses an existing match from the GKTurnBasedMatchmakerViewController, or when a new turn notification comes in.
 */
- (void)takeTurn:(GKTurnBasedMatch *)match;

/*
 receiveEndGame方法当一个比赛结束了玩家的回合时，
 或者当我们接收到一个比赛已经结束的通知或者其他玩家的回合时被调用。
 对于这个简单的游戏来说，当turn-based游戏的NSData达到上限时（4096 bytes）时，我们就结束游戏。
 The receiveEndGame method will be called when a match has ended on our player’s turn, or when we receive a notification that has a match has ended on another player’s turn. For this simple game, we’ll just end the game when we are getting close to the current NSData turn-based game size limit (4096 bytes).
 */
- (void)recieveEndGame:(GKTurnBasedMatch *)match;
/*
 The sendNotice method happens when we receive an event (update turn, end game) on a match that isn’t one we’re currently looking at. If we receive an end game notice on a match that we’ve got loaded into our currentMatch variable, we’ll update the UI to reflect the current state of that match, but if we receive the same notice on a match other than the one we’re looking at, we don’t want to automatically throw the user into that match, taking them away from the match they are currently looking at. We’ll decide later how to handle those notices.
 */
- (void)sendNotice:(NSString *)notice
          forMatch:(GKTurnBasedMatch *)match;
@end

@interface GCTurnBasedMatchHelper: NSObject<GKTurnBasedMatchmakerViewControllerDelegate,
                                            GKLocalPlayerListener>
{
    UIViewController *presentingViewController;
}

@property (nonatomic, weak) id <GCTurnBasedMatchHelperDelegate> delegate;

@property (assign) BOOL userAuthenticated;

// This property holds the last known error
// that occured while using the Game Center API's
@property (nonatomic, readonly) NSError* lastError;

@property (strong)GKTurnBasedMatch * currentMatch;

+ (GCTurnBasedMatchHelper *)sharedInstance;

- (void)authenticateLocalUser;

- (void)findMatchWithMinPlayers:(int)minPlayers
                     maxPlayers:(int)maxPlayers
                 viewController:(UIViewController *)viewController;
@end
