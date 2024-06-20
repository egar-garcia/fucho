  rem Fucho
  rem Author: Egar Garcia
  rem Last Revision 2024-06-04

  set kernel_options player1colors playercolors pfcolors
  set tv ntsc
  set romsize 4k
  set smartbranching on

  const pfscore               =   1

  const MIN_BALLX             =  22
  const MAX_BALLX             = 141
  const MIN_BALLY             =  16
  const MAX_BALLY             =  79

  const MID_BALLX             =  82
  const MID_BALLY             =  48

  const PUSH_BALL_SPEED       =   2
  const HIT_BALL_SPEED        =   3

  const MIN_PX                =  20
  const MAX_PX                = 134
  const MIN_PY                =  27
  const MAX_PY                =  80

  const P_WIDTH               =   8
  const P_HEIGHT              =  12

  const P_MAX_FIRECYCLES      =  30

  const INIT_P0X              =  31
  const INIT_P0Y              =  54
  const INIT_P1X              = 123
  const INIT_P1Y              =  54

  const PUSH_DISPLACEMENT     =   1
  const HIT_DISPLACEMENT      =   5

  const FORWARD               = $01
  const BACKWARD              = $FF
  const NO_MOVE               = $00

  const MIN_GOAL_LIMIT        =  40
  const MAX_GOAL_LIMIT        =  55

  const GOAL_NO_CYCLES        =  90

  const KICKOFF_DIST          =  15

  const STOPPED               =   0
  const IN_PROGRESS           =   1
  const SELECT_PRESSED        =   2
  const RESET_PRESSED         =   3

  const SCORE_LIMIT           =   4

  data BALL_SPEED_CYCLES
    0, 2, 5, 30
end

  dim   balldx                =   a
  dim   balldy                =   b
  dim   ballspeed             =   c
  dim   ballspeedcycle        =   d

  dim   p0dx                  =   e
  dim   p0dy                  =   f
  dim   p0firecycle           =   g
  dim   p0frm                 =   h
  dim   p0score               =   i

  dim   p1dx                  =   j
  dim   p1dy                  =   k
  dim   p1firecycle           =   l
  dim   p1frm                 =   m
  dim   p1score               =   n

  dim   goalcyclecounter      =   o

  dim   playerkickoff         =   p

  dim   gamestate             =   q

  dim   aud0timer             =   r
  dim   aud1timer             =   s

  dim   tmp0                  =   t
  dim   tmp1                  =   u
  dim   tmp2                  =   v
  dim   tmp3                  =   w
  dim   tmp4                  =   x
  dim   tmp5                  =   y

  playfield:
    ................................
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    X..............................X
    X..............................X
    X..............................X
    ................................
    ................................
    X..............................X
    X..............................X
    X..............................X
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
end

  pfscore1 = 0
  pfscore2 = 0
  gosub stop_game

mainloop
  gosub handle_sounds

  if gamestate = SELECT_PRESSED then gosub handle_select_pressed : goto mainloop_draw_screen
  if gamestate = RESET_PRESSED then gosub handle_reset_pressed : goto mainloop_draw_screen

  rem Start or Re-Start the game
  if switchreset then gosub start_game : gamestate = RESET_PRESSED : goto mainloop_draw_screen

  if gamestate = STOPPED     then gosub handle_stopped_game
  if gamestate = IN_PROGRESS then gosub handle_game_in_progress

mainloop_draw_screen
  drawscreen
  goto mainloop


handle_select_pressed
  if switchselect then return
  gamestate = STOPPED
  return

handle_reset_pressed
  if switchreset then return
  gamestate = IN_PROGRESS
  return

handle_stopped_game
  if joy0fire || joy1fire then gosub start_game : gamestate = IN_PROGRESS
  return

handle_game_in_progress
  rem Pause Game
  if switchbw then return

  rem Terminate Game
  if switchselect then gosub stop_game : gamestate = SELECT_PRESSED : return

  if goalcyclecounter = 0 then gosub check_for_goal
  if goalcyclecounter > 0 then gosub handle_goal_celebration : return
  if p0score >= SCORE_LIMIT || p1score >= SCORE_LIMIT then gosub stop_game : gamestate = STOPPED : return

  if collision(player0, player1) then gosub manage_players_collision
  if collision(ball, player0)    then gosub manage_ball_p0_collision
  if collision(ball, player1)    then gosub manage_ball_p1_collision
  if collision(ball, playfield)  then gosub process_collision_ball_playfield

  gosub process_ball_movement
  gosub process_p0_movement
  gosub process_p1_movement

  return


  rem ************************************************************************
  rem * INITIAL POSITIONS
  rem ************************************************************************

set_p0_init_position
  gosub set_p0_init_frame
  player0x = INIT_P0X
  player0y = INIT_P0Y
  p0dx = NO_MOVE
  p0dy = NO_MOVE
  p0firecycle = 0
  p0frm = 0
  return

set_p1_init_position
  player1:
    %00100010
    %01100110
    %01111110
    %01111110
    %01111110
    %01111111
    %11111110
    %01111110
    %01111110
    %01011010
    %01011010
    %01111110
end
  player1x = INIT_P1X
  player1y = INIT_P1Y
  p1dx = NO_MOVE
  p1dy = NO_MOVE
  p1firecycle = 0
  p1frm = 0
  return


set_ball_mid_position
  ballx = MID_BALLX
  bally = MID_BALLY
  balldx = NO_MOVE
  balldy = NO_MOVE
  ballspeed = 0
  ballspeedcycle = 0
  return


  rem ************************************************************
  rem * STOP GAME
  rem ************************************************************

stop_game
  pfcolors:
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
end
  player0color:
    $0A
    $04
    $04
    $06
    $06
    $06
    $06
    $0A
    $0A
    $0A
    $0A
    $0A
end
  player1color:
    $0A
    $04
    $04
    $06
    $06
    $06
    $06
    $0A
    $0A
    $0A
    $0A
    $0A
end
  pfscorecolor = $04
  gosub set_ball_mid_position
  gosub set_p0_init_position
  gosub set_p1_init_position
  return


  rem ************************************************************************
  rem * START GAME
  rem ************************************************************************

start_game
  gosub activate_playfield
  player0color:
    $F6
    $94
    $94
    $98
    $98
    $98
    $98
    $F6
    $F6
    $F6
    $F6
    $F6
end
  player1color:
    $FC
    $34
    $34
    $38
    $38
    $38
    $38
    $FC
    $FC
    $FC
    $FC
    $FC
end
  pfscorecolor = $0F
  pfscore1 = 0
  pfscore2 = 0
  p0score = 0
  p1score = 0
  goalcyclecounter = 0
  playerkickoff = rand & $01
  gosub kickoff
  return

activate_playfield
  pfcolors:
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
end
  return


  rem ************************************************************************
  rem * KICKOFF
  rem ************************************************************************

kickoff
  gosub set_p0_init_position
  gosub set_p1_init_position
  gosub set_ball_mid_position
  if playerkickoff = 0 then ballx = player0x + P_WIDTH + KICKOFF_DIST else ballx = player1x - KICKOFF_DIST
  return


  rem ************************************************************************
  rem * GOAL HANDLING
  rem ************************************************************************

check_for_goal
  if bally < MIN_GOAL_LIMIT || bally > MAX_GOAL_LIMIT then return
  if ballx >= MIN_BALLX && ballx <= MAX_BALLX then return

  if ballx > MAX_BALLX then playerkickoff = 1 : gosub process_p0_goal
  if ballx < MIN_BALLX then playerkickoff = 0 : gosub process_p1_goal

  goalcyclecounter = GOAL_NO_CYCLES
  gosub play_goal_sound
  return

process_p0_goal
  p0score = p0score + 1
  if p0score = 1 then pfscore1 = 2 else pfscore1 = pfscore1 * 4 + 2
  return

process_p1_goal
  p1score = p1score + 1
  if p1score = 1 then pfscore2 = 2 else pfscore2 = pfscore2 * 4 + 2
  return

handle_goal_celebration
  if goalcyclecounter = 0 then return
  goalcyclecounter = goalcyclecounter - 1
  if goalcyclecounter > 0 then return
end
  gosub kickoff
  return


  rem ************************************************************************
  rem * COLLISION BETWEEN PLAYERS
  rem ************************************************************************

manage_players_collision
  tmp0 = PUSH_DISPLACEMENT
  tmp1 = PUSH_DISPLACEMENT
  if p0firecycle > 0 && p0firecycle < P_MAX_FIRECYCLES then tmp0 = HIT_DISPLACEMENT
  if p1firecycle > 0 && p1firecycle < P_MAX_FIRECYCLES then tmp1 = HIT_DISPLACEMENT

  if player0x < player1x then player0x = player0x - tmp1 : player1x = player1x + tmp0
  if player0x > player1x then player0x = player0x + tmp1 : player1x = player1x - tmp0
  if player0y < player1y then player0y = player0y - tmp1 : player1y = player1y + tmp0
  if player0y > player1y then player0y = player0y + tmp1 : player1y = player1y - tmp0

  if tmp0 >= HIT_DISPLACEMENT || tmp1 >= HIT_DISPLACEMENT then gosub play_hit_sound else gosub play_ball_bounce_sound
  return


  rem ************************************************************************
  rem * COLLISION BETWEEN PLAYER 0 AND BALL
  rem ************************************************************************

manage_ball_p0_collision
  tmp0 = p0dx
  tmp1 = p0dy
  tmp2 = p0firecycle
  gosub manage_ball_player_collision
  return


  rem ************************************************************************
  rem * COLLISION BETWEEN PLAYER 1 AND BALL
  rem ************************************************************************

manage_ball_p1_collision
  tmp0 = p1dx
  tmp1 = p1dy
  tmp2 = p1firecycle
  gosub manage_ball_player_collision
  return


  rem ************************************************************************
  rem * METHODS TO HANDLE COLLISIONS BETWEEN PLAYERS AND BALL
  rem ************************************************************************

manage_ball_player_collision
  rem PARAM: tmp0 - The player's direction in X
  rem PARAM: tmp1 - The player's direction in Y
  rem PARAM: tmp2 - The player's firecycle

  if tmp0 = NO_MOVE && tmp1 = NO_MOVE then tmp3 = 0 else tmp3 = PUSH_BALL_SPEED
  if tmp2 > 0 && tmp2 < P_MAX_FIRECYCLES then tmp3 = HIT_BALL_SPEED

  gosub manage_ball_player_collision_x
  gosub manage_ball_player_collision_y

  if ballspeed >= tmp3 then return

  if tmp3 >= HIT_BALL_SPEED then gosub play_hit_sound else gosub play_ball_bounce_sound
  ballspeed = tmp3
  gosub set_ball_speed
  return

manage_ball_player_collision_x
  rem PARAM: tmp0 - The player's direction in X

  if balldx = NO_MOVE && tmp0 = NO_MOVE then return

  if balldx = NO_MOVE then balldx = tmp0 : return

  if balldx = FORWARD  && tmp0 = NO_MOVE  then balldx = BACKWARD : return
  if balldx = BACKWARD && tmp0 = NO_MOVE  then balldx = FORWARD  : return
  if balldx = FORWARD  && tmp0 = BACKWARD then balldx = BACKWARD : return
  if balldx = BACKWARD && tmp0 = FORWARD  then balldx = FORWARD  : return

  if balldx = FORWARD  then balldx = BACKWARD
  if balldx = BACKWARD then balldx = FORWARD
  return

manage_ball_player_collision_y
  rem PARAM: tmp1 - The player's direction in Y

  if balldy = NO_MOVE && tmp1 = NO_MOVE then return

  if balldy = NO_MOVE then balldy = tmp1 : return

  if balldy = FORWARD  && tmp1 = NO_MOVE  then balldy = BACKWARD : return
  if balldy = BACKWARD && tmp1 = NO_MOVE  then balldy = FORWARD  : return
  if balldy = FORWARD  && tmp1 = BACKWARD then balldy = BACKWARD : return
  if balldy = BACKWARD && tmp1 = FORWARD  then balldy = FORWARD  : return

  if balldy = FORWARD  then balldy = BACKWARD
  if balldy = BACKWARD then balldy = FORWARD
  return


  rem ************************************************************************
  rem * COLLISION BETWEEN BALL AND PLAYFIELD
  rem ************************************************************************

process_collision_ball_playfield
  if ballx < MIN_BALLX then balldx = FORWARD
  if ballx > MAX_BALLX then balldx = BACKWARD
  if bally < MIN_BALLY then balldy = FORWARD
  if bally > MAX_BALLY then balldy = BACKWARD
  gosub play_ball_bounce_sound
  return


  rem ************************************************************************
  rem * BALL MOVEMENT
  rem ************************************************************************

process_ball_movement
  gosub check_ball_limits

  if ballspeed = 0 then return

  for z = 1 to ballspeed
    gosub process_ball_unitary_movement
  next

  ballspeedcycle = ballspeedcycle - 1
  if ballspeedcycle = 0 then ballspeed = ballspeed - 1 : gosub set_ball_speed : return
  return

process_ball_unitary_movement
  ballx = ballx + balldx
  bally = bally + balldy
  return

set_ball_speed
  if ballspeed = 0 then balldx = NO_MOVE : balldy = NO_MOVE : return
  ballspeedcycle = BALL_SPEED_CYCLES[ballspeed]
  return

check_ball_limits
  if ballx < MIN_BALLX then ballx = MIN_BALLX
  if ballx > MAX_BALLX then ballx = MAX_BALLX
  if bally < MIN_BALLY then bally = MIN_BALLY
  if bally > MAX_BALLY then bally = MAX_BALLY
  return


  rem ************************************************************************
  rem * PLAYER 0 MOVEMENT
  rem ************************************************************************

process_p0_movement
  p0dx = NO_MOVE
  p0dy = NO_MOVE
  if switchleftb then gosub set_p0_player_movement else gosub set_p0_cpu_movement
  gosub perform_p0_movement
  return

set_p0_player_movement
  if joy0fire then p0firecycle = p0firecycle + 1 else p0firecycle = 0
  if joy0left  then p0dx = BACKWARD
  if joy0right then p0dx = FORWARD
  if joy0up    then p0dy = BACKWARD
  if joy0down  then p0dy = FORWARD
  return

perform_p0_movement
  player0x = player0x + p0dx
  player0y = player0y + p0dy
  if player0x < MIN_PX then player0x = MIN_PX
  if player0x > MAX_PX then player0x = MAX_PX
  if player0y < MIN_PY then player0y = MIN_PY
  if player0y > MAX_PY then player0y = MAX_PY
  gosub process_p0_frame
  return

process_p0_frame
  if p0firecycle > 0 && p0firecycle <= P_MAX_FIRECYCLES then gosub set_p0_hit_frame : return

  gosub advance_p0_frame
  if p0frm >= 20 then p0frm = 0
  if p0frm < 10 then gosub set_p0_init_frame
  if p0frm >= 10 then player0:
    %00100010
    %01100110
    %01111110
    %01111110
    %01111110
    %01111111
    %11111110
    %01111110
    %01111110
    %01011010
    %01011010
    %01111110
end
  return

set_p0_hit_frame
  player0:
    %01000010
    %01100110
    %01111110
    %01111110
    %01111110
    %01111110
    %11111111
    %01111110
    %01100110
    %01111110
    %01011010
    %01111110
end
  return

set_p0_init_frame
  player0:
    %01000100
    %01100110
    %01111110
    %01111110
    %01111110
    %11111110
    %01111111
    %01111110
    %01111110
    %01011010
    %01011010
    %01111110
end
  return

advance_p0_frame
  if p0dx = NO_MOVE && p0dy = NO_MOVE then return
  p0frm = p0frm + 1
  return


  rem ************************************************************************
  rem * PLAYER 1 MOVEMENT
  rem ************************************************************************

process_p1_movement
  p1dx = NO_MOVE
  p1dy = NO_MOVE
  if switchrightb then gosub set_p1_player_movement else gosub set_p1_cpu_movement
  gosub perform_p1_movement
  return

set_p1_player_movement
  if joy1fire then p1firecycle = p1firecycle + 1 else p1firecycle = 0
  if joy1left  then p1dx = BACKWARD
  if joy1right then p1dx = FORWARD
  if joy1up    then p1dy = BACKWARD
  if joy1down  then p1dy = FORWARD
  return

perform_p1_movement
  player1x = player1x + p1dx
  player1y = player1y + p1dy
  if player1x < MIN_PX then player1x = MIN_PX
  if player1x > MAX_PX then player1x = MAX_PX
  if player1y < MIN_PY then player1y = MIN_PY
  if player1y > MAX_PY then player1y = MAX_PY
  gosub process_p1_frame
  return

process_p1_frame
  if p1firecycle > 0 && p1firecycle <= P_MAX_FIRECYCLES then gosub set_p1_hit_frame : return

  gosub advance_p1_frame
  if p1frm >= 20 then p1frm = 0
  if p1frm < 10 then gosub set_p1_init_frame
  if p1frm >= 10 then player1:
    %01000100
    %01100110
    %01111110
    %01111110
    %01111110
    %11111110
    %01111111
    %01111110
    %01111110
    %01011010
    %01011010
    %01111110
end
  return

set_p1_init_frame
  player1:
    %00100010
    %01100110
    %01111110
    %01111110
    %01111110
    %01111111
    %11111110
    %01111110
    %01111110
    %01011010
    %01011010
    %01111110
end
  return

set_p1_hit_frame
  player1:
    %01000010
    %01100110
    %01111110
    %01111110
    %01111110
    %01111110
    %11111111
    %01111110
    %01100110
    %01111110
    %01011010
    %01111110
end
  return

advance_p1_frame
  if p1dx = NO_MOVE && p1dy = NO_MOVE then return
  p1frm = p1frm + 1
  return


  rem ************************************************************************
  rem * CPU PLAYER'S MOVEMENT
  rem ************************************************************************

set_p0_cpu_movement
  gosub players_are_touching
  tmp1 = rand & $01
  if tmp0 = 1 && tmp1 > 0 && p0firecycle = 0 then p0firecycle = 1

  tmp0 = rand & $0F
  if tmp0 >= $0F then return

  tmp0 = ballx - 1
  tmp1 = bally + 1
  tmp2 = player0x + P_WIDTH
  tmp3 = player0y - P_HEIGHT
  if player0x <= tmp0 && tmp0 <= tmp2 && tmp3 < tmp1 && tmp1 <= player0y then gosub set_p0_cpu_shoot else gosub set_p0_cpu_in_position return

  if p0firecycle > P_MAX_FIRECYCLES then p0firecycle = 0
  if p0firecycle > 0 then p0firecycle = p0firecycle + 1
  return

set_p0_cpu_in_position
  p1dx = NO_MOVE

  tmp0 = player0x + P_WIDTH
  tmp1 = ballx - 1
  if tmp0 < tmp1 then p0dx = FORWARD
  if tmp0 > tmp1 then p0dx = BACKWARD

  tmp0 = player0y
  if p0dx <> BACKWARD then tmp1 = 0 else tmp1 = 1
  gosub set_player_cpu_in_position_y
  p0dy = tmp2
  return

set_p0_cpu_shoot
  p0dx = FORWARD

  tmp0 = player0y
  tmp1 = player1y
  gosub set_player_cpu_shoot_y
  p0dy = tmp2

  if p0firecycle = 0 then p0firecycle = 1
  return

set_p1_cpu_movement
  gosub players_are_touching
  tmp1 = rand & $01
  if tmp0 = 1 && tmp1 > 0 && p1firecycle = 0 then p1firecycle = 1

  tmp0 = rand & $0F
  if tmp0 >= $0F then return

  tmp0 = ballx - 1
  tmp1 = bally + 1
  tmp2 = player1x + P_WIDTH
  tmp3 = player1y - P_HEIGHT
  tmp4 = player1x - 1
  if tmp4 <= tmp0 && tmp0 < tmp2 && tmp3 < tmp1 && tmp1 <= player1y then gosub set_p1_cpu_shoot else gosub set_p1_cpu_in_position return

  if p1firecycle > P_MAX_FIRECYCLES then p1firecycle = 0
  if p1firecycle > 0 then p1firecycle = p1firecycle + 1
  return

set_p1_cpu_in_position
  p1dx = NO_MOVE
  if player1x > ballx then p1dx = BACKWARD
  if player1x < ballx then p1dx = FORWARD

  tmp0 = player1y
  if p1dx <> FORWARD then tmp1 = 0 else tmp1 = 1
  gosub set_player_cpu_in_position_y
  p1dy = tmp2
  return

set_p1_cpu_shoot
  p1dx = BACKWARD

  tmp0 = player1y
  tmp1 = player0y
  gosub set_player_cpu_shoot_y
  p1dy = tmp2

  if p1firecycle = 0 then p1firecycle = 1
  return

set_player_cpu_in_position_y
  rem PARAM: tmp0 - The player's Y position
  rem PARAM: tmp1 - Center ball: 0, Avoid ball: 1
  rem RETURN: tmp2 - The player's direction in Y
  tmp2 = NO_MOVE

  tmp3 = tmp0 - P_HEIGHT / 2
  if tmp3 < bally then tmp2 = FORWARD
  if tmp3 > bally then tmp2 = BACKWARD

  if tmp1 = 0 then return 

  tmp4 = bally + 1
  tmp5 = tmp0 - P_HEIGHT
  if tmp0 < bally || tmp4 < tmp5 then return
  if tmp0 = bally || tmp4 = tmp5 then tmp2 = NO_MOVE : return
  if tmp2 = FORWARD then tmp2 = BACKWARD else tmp2 = FORWARD
  return

set_player_cpu_shoot_y
  rem PARAM: tmp0 - The player's Y position
  rem PARAM: tmp1 - The oponent player's Y position
  rem RETURN: tmp2 - The player's direction in Y
  tmp2 = NO_MOVE

  tmp3 = tmp0 - P_HEIGHT
  tmp4 = tmp0 - 3
  tmp5 = tmp3 + 2
  if bally >= tmp4 then tmp2 = FORWARD  : return
  if bally <= tmp5 then tmp2 = BACKWARD : return

  tmp4 = tmp1 - P_HEIGHT
  if tmp4 < tmp0 && tmp0 <= tmp1 then tmp2 = BACKWARD  : return
  if tmp3 < tmp1 && tmp1 <= tmp0 then tmp2 = FORWARD  : return

  if bally < MIN_GOAL_LIMIT then tmp2 = FORWARD
  if bally > MAX_GOAL_LIMIT then tmp2 = BACKWARD
  return

players_are_touching
  rem RETURN: tmp0 - If players are touching 1, 0 otherwise
  if player0x < player1x then tmp1 = player1x - player0x else tmp1 = player0x - player1x
  if player0y < player1y then tmp1 = player1y - player0y else tmp2 = player0y - player1y
  if tmp1 < P_WIDTH && tmp2 < P_HEIGHT then tmp0 = 1 else tmp0 = 0
  return


  rem ************************************************************************
  rem * SOUND HANDLING
  rem ************************************************************************

handle_sounds
  if aud0timer > 1 then aud0timer = aud0timer - 1
  if aud0timer = 1 then aud0timer = 0 : gosub clear_sound0
  if aud1timer > 1 then aud1timer = aud1timer - 1
  if aud1timer = 1 then aud1timer = 0 : gosub clear_sound1
  return

clear_sound0
  AUDV0 = 0
  AUDC0 = 0
  AUDF0 = 0
  return

clear_sound1
  AUDV1 = 0
  AUDC1 = 0
  AUDF1 = 0
  return

play_ball_bounce_sound
  AUDV0 = 5
  AUDC0 = 10
  AUDF0 = 20
  aud0timer = 5
  return

play_hit_sound
  AUDV1 = 15
  AUDC1 = 15
  AUDF1 = 31
  aud1timer = 10
  return

play_goal_sound
  AUDV1 = 15
  AUDC1 = 10
  AUDF1 = 5
  aud1timer = 20
  return
