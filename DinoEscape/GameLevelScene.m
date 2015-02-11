//
//  GameLevelScene.m
//

#import "GameLevelScene.h"
#import "JSTileMap.h"
#import "Player.h"
#import "SKTUtils.h"

@interface GameLevelScene()
@property (nonatomic, strong) JSTileMap *map;
@property (nonatomic, strong) Player *player;
@property (nonatomic, assign) NSTimeInterval previousUpdateTime;
@property (nonatomic, strong) TMXLayer *walls;
@property (nonatomic, strong) TMXLayer *hazards;
@property (nonatomic, assign) BOOL gameOver;
@property (nonatomic, strong) UIButton *replay;
@end

@implementation GameLevelScene

-(id)initWithSize:(CGSize)size {
  if (self = [super initWithSize:size]) {
      
      //touch setup
      self.userInteractionEnabled = YES;
      
      //scene setup
      self.backgroundColor = [SKColor colorWithRed:.4 green:.4 blue:.95 alpha:1.0];
      self.map = [JSTileMap mapNamed:@"level1.tmx"];
      [self addChild:self.map];
      
      //get walls and hazards
      self.walls = [self.map layerNamed:@"walls"];
      self.hazards = [self.map layerNamed:@"hazards"];
      
      //player setup
      SKTexture *texture = [SKTexture textureWithImageNamed:@"small_stand"];
      texture.filteringMode = SKTextureFilteringNearest;
      self.player = [Player spriteNodeWithTexture:texture];
      [self.player setScale:.5];
      self.player.position = CGPointMake(100, 50);
      self.player.zPosition = 15;
      [self.map addChild:self.player];
      
      //setup replay button
      self.replay = [UIButton buttonWithType:UIButtonTypeCustom];
      UIImage *replayImage = [UIImage imageNamed:@"replay"];
      [self.replay setImage:replayImage forState:UIControlStateNormal];
      [self.replay addTarget:self action:@selector(replay:) forControlEvents:UIControlEventTouchUpInside];
      self.replay.frame = CGRectMake(self.size.width / 2.0 - replayImage.size.width / 2.0, self.size.height / 2.0 - replayImage.size.height / 2.0, replayImage.size.width, replayImage.size.height);
  }
  return self;
}

//essentially our 'render' method
- (void)update:(NSTimeInterval)currentTime
{
    //first check for game over
    if (self.gameOver) return;
    
    NSTimeInterval delta = currentTime - self.previousUpdateTime;
    //cap delta time so we don't see unexpected behavior
    if (delta > 0.02) {
        delta = 0.02;
    }
    self.previousUpdateTime = currentTime;
    [self.player update:delta];
    [self checkForAndResolveCollisionsForPlayer:self.player forLayer:self.walls];
    [self handleHazardCollisions:self.player];
    [self checkForWin];
    [self setViewpointCenter:self.player.position];
}

//collision stuff
//takes a tile’s coordinates and returns the rect in pixel coordinates.
-(CGRect)tileRectFromTileCoords:(CGPoint)tileCoords {
    float levelHeightInPixels = self.map.mapSize.height * self.map.tileSize.height;
    CGPoint origin = CGPointMake(tileCoords.x * self.map.tileSize.width, levelHeightInPixels - ((tileCoords.y + 1) * self.map.tileSize.height));
    return CGRectMake(origin.x, origin.y, self.map.tileSize.width, self.map.tileSize.height);
}

//looks up the GID of a tile at a given coordinate
- (NSInteger)tileGIDAtTileCoord:(CGPoint)coord forLayer:(TMXLayer *)layer {
    TMXLayerInfo *layerInfo = layer.layerInfo;
    return [layerInfo tileGidAtCoord:coord];
}

- (void)checkForAndResolveCollisionsForPlayer:(Player *)player forLayer:(TMXLayer *)layer
{
    NSInteger indices[8] = {7, 1, 3, 5, 0, 2, 6, 8};
    player.onGround = NO;
    for (NSUInteger i = 0; i < 8; i++) {
        NSInteger tileIndex = indices[i];
        
        CGRect playerRect = [player collisionBoundingBox];
        CGPoint playerCoord = [layer coordForPoint:player.desiredPosition];
        
        //make sure we're not out the bottom of the map
        if (playerCoord.y >= self.map.mapSize.height - 1) {
            [self gameOver:0];
            return;
        }
        
        NSInteger tileColumn = tileIndex % 3;
        NSInteger tileRow = tileIndex / 3;
        CGPoint tileCoord = CGPointMake(playerCoord.x + (tileColumn - 1), playerCoord.y + (tileRow - 1));
        
        NSInteger gid = [self tileGIDAtTileCoord:tileCoord forLayer:layer];
        if (gid != 0) {
            CGRect tileRect = [self tileRectFromTileCoords:tileCoord];
            if (CGRectIntersectsRect(playerRect, tileRect)) {
                CGRect intersection = CGRectIntersection(playerRect, tileRect);
                if (tileIndex == 7) {
                    //tile is directly below Dino
                    player.desiredPosition = CGPointMake(player.desiredPosition.x, player.desiredPosition.y + intersection.size.height);
                    player.velocity = CGPointMake(player.velocity.x, 0.0);
                    player.onGround = YES;
                } else if (tileIndex == 1) {
                    //tile is directly above Dino
                    player.desiredPosition = CGPointMake(player.desiredPosition.x, player.desiredPosition.y - intersection.size.height);
                    //TODO: something here with upwards velocity?
                    player.collidedTop = YES;
                } else if (tileIndex == 3) {
                    //tile is left of Dino
                    player.desiredPosition = CGPointMake(player.desiredPosition.x + intersection.size.width, player.desiredPosition.y);
                } else if (tileIndex == 5) {
                    //tile is right of Dino
                    player.desiredPosition = CGPointMake(player.desiredPosition.x - intersection.size.width, player.desiredPosition.y);
                    //3
                } else {
                    if (intersection.size.width > intersection.size.height) {
                        //tile is diagonal, but resolving collision vertically
                        player.velocity = CGPointMake(player.velocity.x, 0.0);
                        float intersectionHeight;
                        if (tileIndex > 4) {
                            intersectionHeight = intersection.size.height;
                            player.onGround = YES;
                        } else {
                            intersectionHeight = -intersection.size.height;
                        }
                        player.desiredPosition = CGPointMake(player.desiredPosition.x, player.desiredPosition.y + intersection.size.height );
                    } else {
                        //tile is diagonal, but resolving horizontally
                        float intersectionWidth;
                        if (tileIndex == 6 || tileIndex == 0) {
                            intersectionWidth = intersection.size.width;
                        } else {
                            intersectionWidth = -intersection.size.width;
                        }
                        player.desiredPosition = CGPointMake(player.desiredPosition.x  + intersectionWidth, player.desiredPosition.y);
                    }
                }
            }
        }
    }
    //6
    player.position = player.desiredPosition;
}

- (void)handleHazardCollisions:(Player *)player
{
    //first check for end of the game
    if (self.gameOver) return;
    
    NSInteger indices[8] = {7, 1, 3, 5, 0, 2, 6, 8};
    
    for (NSUInteger i = 0; i < 8; i++) {
        NSInteger tileIndex = indices[i];
        
        CGRect playerRect = [player collisionBoundingBox];
        CGPoint playerCoord = [self.hazards coordForPoint:player.desiredPosition];
        
        NSInteger tileColumn = tileIndex % 3;
        NSInteger tileRow = tileIndex / 3;
        CGPoint tileCoord = CGPointMake(playerCoord.x + (tileColumn - 1), playerCoord.y + (tileRow - 1));
        
        NSInteger gid = [self tileGIDAtTileCoord:tileCoord forLayer:self.hazards];
        if (gid != 0) {
            CGRect tileRect = [self tileRectFromTileCoords:tileCoord];
            if (CGRectIntersectsRect(playerRect, tileRect)) {
                [self gameOver:0];
            }
        }
    }
}

//movement
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.player.forwardMarch = YES;
    self.player.mightAsWellJump = YES;
    self.player.onGround = NO;
    self.player.texture = [SKTexture textureWithImageNamed:@"small_walk"];
    self.player.isStand = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        
        float halfWidth = self.size.width / 2.0;
        CGPoint touchLocation = [touch locationInNode:self];
        
        //get previous touch and convert it to node space
        CGPoint previousTouchLocation = [touch previousLocationInNode:self];
        
        if (touchLocation.x > halfWidth && previousTouchLocation.x <= halfWidth) {
            self.player.forwardMarch = NO;
            self.player.mightAsWellJump = YES;
        } else if (previousTouchLocation.x > halfWidth && touchLocation.x <= halfWidth) {
            self.player.forwardMarch = YES;
            self.player.mightAsWellJump = NO;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.player.mightAsWellJump = NO;
}

//map movement
- (void)setViewpointCenter:(CGPoint)position {
    NSInteger x = MAX(position.x, self.size.width / 2);
    NSInteger y = MAX(position.y, self.size.height / 2);
    x = MIN(x, (self.map.mapSize.width * self.map.tileSize.width) - self.size.width / 2);
    y = MIN(y, (self.map.mapSize.height * self.map.tileSize.height) - self.size.height / 2);
    CGPoint actualPosition = CGPointMake(x, y);
    CGPoint centerOfView = CGPointMake(self.size.width/2, self.size.height/2);
    CGPoint viewPoint = CGPointSubtract(centerOfView, actualPosition);
    self.map.position = viewPoint;
}

//end game
-(void)gameOver:(BOOL)won {
    self.gameOver = YES;
    NSString *gameText;
    if (won) {
        gameText = @"You Won!";
    } else {
        gameText = @"You have Died!";
        self.player.texture = [SKTexture textureWithImageNamed:@"small_sad"];
    }
    
    SKLabelNode *endGameLabel = [SKLabelNode labelNodeWithFontNamed:@"Marker Felt"];
    endGameLabel.text = gameText;
    endGameLabel.fontSize = 32;
    endGameLabel.position = CGPointMake(self.size.width / 2.0, self.size.height / 1.7);
    [self addChild:endGameLabel];

    //add replay button
    [self.view addSubview:self.replay];
}

- (void)replay:(id)sender
{
    [self.replay removeFromSuperview];
    [self.view presentScene:[[GameLevelScene alloc] initWithSize:self.size]];
}

-(void)checkForWin {
    if (self.player.position.x > 3130.0) {
        [self gameOver:1];
    }
}


@end
