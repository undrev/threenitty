//
//
// Three'n'itty - the game entry for Gaijin Jam #2
// 2022 (c) UNDREV
//
// Version: 1.0.1
//
// Three life forms want to survive on malfunctioning
// spaceship drifting in deep space.
//
// The game's genre is: TBS, quest, puzzle, roguelite.
//
// Pass through 8 levels, follow the quests, get some
// loot to keep your HP and energy level high, solve
// puzzles to unlock the doors. You have to save lifes
// of the colonists, Kate (your wife) and Flowey (your
// wife's favorite plant).
//
// Control (keyboard only): [WASD] to move, [ENTER] to
// use ITTy (a handheld teleporting tool).
//
// ITTy works in two ways: one [ENTER] hit -- the target
// object will be teleported into ITTy and you can carry
// it; second [ENTER] hit -- ITTy puts the object back
// to the floor. You can carry only one object at a time.
// Maximum ITTy's range is 4 steps/cells.
//
// Do not use or share the media (graphics & sfx) aside
// this game package.
//
//

require daslib/media
require daslib/strings_boost

let
    GAME_VERSION = "1.0.1"
	GAME_TITLE = "Three'n'itty by UNDREV, v{GAME_VERSION}"
	WIDTH = 1280
	WIDTH_D2 = 640
	WIDTH_D3 = 430
	WIDTH_D4 = 320
	HEIGHT = 720
	HEIGHT_D2 = 360
	HEIGHT_D3 = 240
	HEIGHT_D4 = 180
	CELL_SIZE = 52
	CELL_WIDTH = 26
	CELL_HEIGHT = 15
    X_OFF = -36
    Y_OFF = -30
    HPOS = -1
    
	BACKGROUND_FADE_COLOR = 0xAA000000
	BACKGROUND_COLOR = 0xFF171737
	STORY_BACKGROUND_COLOR = 0xFF434382
	PUZZLE_BACKGROUND_COLOR = 0xFF266266
    
    HERO_MAX_HP = 10
    HERO_MAX_ENERGY = 10
    HERO_STEPS_PER_HP = 15
    
    ITTY_MAX_RANGE = 4
    MINE_DAMAGE = -4
    
enum StateID
    MENU
    GAME
    STORY
    QUEST
    LOOT
    PUZZLE
    GAMEWIN
    GAMEFAIL

enum SfxID
    MENU
    GAME
    VICTORY
    ITTY
    DUMMY

enum GuiID
    MENU
    HP
    BATTERY
    VICTORY
    DEFEAT
    DUMMY

enum TileID
    FLOOR
    WALL
    MINE
    PD
    BLOCK
    WALL_UP
    WALL_DOWN
    WALL_FLOOR
    WALL_ROCKS
    DOORLOCK
    DOORUNLOCK
    DOORLOCK2
    DOORUNLOCK2
    CP
    PC
    CORPSE
    LOOTBOX
    DA2
    DA3
    DA4
    DA4L
    DA4R
    DA5
    DA5L
    DA6L
    DA6
    SHADOW
    ALARM1
    ALARM2
    ALARM3
    DAMAGE
    FLOWIE
    KATE
    DUMMY

enum LootID
    NONE
    EMPTY
    ITTY
    //
    WATER
    WATER_X2
    JUICE
    BAR
    BAR_X2
    TOMATO
    PEANUTS
    BREAD
    CHOCOLATE
    //
    SODA
    CUPCAKE
    CANDY
    //
    MEDICINE
    MEDICINE_X2
    //
    BATTERY
    BATTERY_X2
    DUMMY

enum PuzzleID
    NONE
    P1
    DUMMY

enum StoryID
    NONE
    START
    ITTY
    ELECTROKATE
    UPLOAD
    DECKA2
    GETSOMELOOT
    FLOWIE
    DECKA3
    PRESSURE1
    DECKA4
    MINEFIELD
    CP1
    DECKA4L
    DECKA5L
    PRESSURE2
    DECKA6L
    DECKA6
    END
    DONTFORGETFLOWIE
    DUMMY

enum DirID
    UP
    DOWN
    LEFT
    RIGHT

enum ItemID
    NONE
    KATE
    FLOWIE
    BLOCK

struct Loot
    img: ImageHandle
    name: string
    data: string
    value: int
    event: string

struct Puzzle
    img: ImageHandle
    data: array<int>

struct Item
    img: ImageHandle
    tid: ItemID
    passable: bool
    ittable: bool
    loot_id: LootID
    story_id: StoryID
    puzzle_id: PuzzleID
    value: int
    event: string

struct Hero
	img: array<ImageHandle>
    dir: DirID
    hp: int
    energy: int
    itty: bool
    kate: bool
    flowie: bool
    carry: bool
	pos: int2
    steps: int

struct Session
    state: StateID
    level: int
    level_txt: string
    seed: int4
    item_pos: int2
    story_id: StoryID
    story_ava: int
    story_page: int
    story_txt: array<string>
    quest_txt: string
    loot_id: LootID
    puzzle_id: PuzzleID
    mines: int
    sfx: PlayingSoundHandle
    mm: array<string>
    nn: array<int2>
    
var
    //GAME
    game: Session
    //SFX
	sfx: array<PcmSound>
    //GUI
	gui: array<ImageHandle>
    //HERO
	hero: Hero
    //LEVEL
	tiles: array<ImageHandle>
	items: table<int2; Item>
	loots: array<Loot>
	puzzles: array<Puzzle>
    avatars: array<ImageHandle>
	story: array<string>
	quest: array<string>
	level: table<int; int[26]>
	items_rc: table<int2; Item>
    //MISC
    RAD <- {{ 0 => 0.0; 90 => 1.5707; 180 => 3.1415; 270 => 4.7123 }}
    
// SFX //
def init_sfx()
    sfx |> resize(int(SfxID DUMMY))
    sfx[int(SfxID MENU)] <- create_sound("assets/sfx/menu.wav")
    sfx[int(SfxID GAME)] <- create_sound("assets/sfx/game.wav")
    sfx[int(SfxID VICTORY)] <- create_sound("assets/sfx/victory.wav")
    sfx[int(SfxID ITTY)] <- create_sound("assets/sfx/itty.wav")

def play_sfx(i: SfxID)
    if is_playing(game.sfx)
        game.sfx |> stop_sound()
    if i == SfxID MENU
        game.sfx = sfx[int(SfxID MENU)] |> play_sound_loop()
    elif i == SfxID GAME
        game.sfx = sfx[int(SfxID GAME)] |> play_sound_loop()
    elif i == SfxID VICTORY
        game.sfx = sfx[int(SfxID VICTORY)] |> play_sound_loop()
    //elif i == SfxID ITTY
        //game.sfx = sfx[int(SfxID ITTY)] |> play_sound()

// GUI //
def init_gui()
    //UI
    gui |> resize(int(GuiID DUMMY))
    gui[int(GuiID MENU)] <- create_managed_image("assets/menu/threenitty.png")
    gui[int(GuiID HP)] <- create_managed_image("assets/game/ui/hp.png")
    gui[int(GuiID BATTERY)] <- create_managed_image("assets/game/ui/battery.png")
    gui[int(GuiID VICTORY)] <- create_managed_image("assets/game/ui/victory.png")
    gui[int(GuiID DEFEAT)] <- create_managed_image("assets/game/ui/defeat.png")

def draw_gui()
    var pos = int2(20, 10)
	enable_alpha_blend()
    gui[int(GuiID HP)] |> draw_image(pos.x, pos.y)
    disable_alpha_blend()
    text_out(pos.x + 50, pos.y + 10, "{hero.hp}/{HERO_MAX_HP}", 0x00FFFF)
    if hero.itty
        pos.x += 140
        enable_alpha_blend()
        gui[int(GuiID BATTERY)] |> draw_image(pos.x, pos.y)
        disable_alpha_blend()
        text_out(pos.x + 50, pos.y + 10, "{hero.energy}/{HERO_MAX_ENERGY} [{items[int2(HPOS, HPOS)].tid}]", 0x00FFFF)
    if length(game.quest_txt) > 0
        pos = int2(20, HEIGHT - 40)
        text_out(pos.x, pos.y, "Current Quest: {game.quest_txt}", 0x00FFFF)
    pos = int2(WIDTH - 160, 20)
    text_out(pos.x, pos.y, "{game.level_txt}", 0x00FFFF)

// MENU //

def draw_menu()
    fill_rect(0, 0, WIDTH, HEIGHT, BACKGROUND_COLOR)
    gui[int(GuiID MENU)] |> draw_image(0, HEIGHT_D3)
    text_out(480, HEIGHT - 300, "Press [ENTER] to start the game", 0x00FFFF)
    text_out(560, HEIGHT - 60, "(c) 2022 UNDREV", 0x00FFFF)
    set_font_size(12)
    text_out(WIDTH - 80, HEIGHT - 40, "v{GAME_VERSION}", 0xFFFFFF)
    set_font_size(16)

// GAME //

def do_event(event: string; value: auto)
    if event == "hp"
        hero.hp += int(value)
        if hero.hp > HERO_MAX_HP
            hero.hp = HERO_MAX_HP
        elif hero.hp <= 0
            hero.hp = 0
            game.state = StateID GAMEFAIL
    elif event == "energy"
        hero.energy += int(value)
        if hero.energy > HERO_MAX_ENERGY
            hero.energy = HERO_MAX_ENERGY
        elif hero.energy < 0
            hero.energy = 0
            game.state = StateID GAMEFAIL
    elif event == "itty"
        hero.itty = true
        game.story_id = StoryID ELECTROKATE
        game.story_txt <- split(story[int(game.story_id)], ";")
        game.state = StateID STORY
    elif event == "electrokate"
        if hero.kate
            items[int2(6, 9)].img = tiles[int(TileID WALL_ROCKS)]
            game.story_id = StoryID UPLOAD
            game.story_txt <- split(story[int(game.story_id)], ";")
            game.state = StateID STORY
    elif event == "da1pc"
        if hero.kate
            game.story_id = StoryID DECKA2
            game.story_txt <- split(story[int(game.story_id)], ";")
            game.state = StateID STORY
            //
            erase(items, int2(HPOS, HPOS))
            items[int2(6, 21)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(6, 21)].passable = true
            items[int2(7, 21)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(7, 21)].passable = true
            items[int2(8, 21)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(8, 21)].passable = true
    elif event == "da2"
        items[int2(6, 22)].img = tiles[int(TileID DOORUNLOCK)]
        items[int2(6, 22)].passable = true
        items[int2(7, 22)].img = tiles[int(TileID DOORUNLOCK)]
        items[int2(7, 22)].passable = true
        items[int2(8, 22)].img = tiles[int(TileID DOORUNLOCK)]
        items[int2(8, 22)].passable = true
    elif event == "da3"
        items[int2(6, 22)].img = tiles[int(TileID DOORUNLOCK)]
        items[int2(6, 22)].passable = true
        items[int2(7, 22)].img = tiles[int(TileID DOORUNLOCK)]
        items[int2(7, 22)].passable = true
        items[int2(8, 22)].img = tiles[int(TileID DOORUNLOCK)]
        items[int2(8, 22)].passable = true
    elif event == "da4"
        game.story_id = StoryID DECKA4L
        game.story_txt <- split(story[int(game.story_id)], ";")
        game.state = StateID STORY
        //
        items[int2(3, 12)].img = tiles[int(TileID DOORUNLOCK2)]
        items[int2(3, 12)].passable = true
        items[int2(3, 13)].img = tiles[int(TileID DOORUNLOCK2)]
        items[int2(3, 13)].passable = true
        items[int2(3, 14)].img = tiles[int(TileID DOORUNLOCK2)]
        items[int2(3, 14)].passable = true
    elif event == "da6pc"
        play_sfx(SfxID VICTORY)
        game.state = StateID GAMEWIN
        game.level = 1
    elif event == "level"
        if hero.itty && hero.flowie
            game.level += 1
            load_game()
        else
            game.story_id = StoryID DONTFORGETFLOWIE
            game.story_txt <- split(story[int(game.story_id)], ";")
            game.state = StateID STORY
    

// HERO //

def init_hero()
    hero.img |> resize(4)
	hero.img[int(DirID UP)] <- create_managed_image("assets/game/hero_up.png")
	hero.img[int(DirID DOWN)] <- create_managed_image("assets/game/hero_down.png")
	hero.img[int(DirID LEFT)] <- create_managed_image("assets/game/hero_left.png")
	hero.img[int(DirID RIGHT)] <- create_managed_image("assets/game/hero_right.png")
    hero.steps = HERO_STEPS_PER_HP
    hero.itty = false
    hero.kate = false
    hero.flowie = false
    //
    hero.dir = DirID DOWN
    hero.hp = 5
    hero.energy = 0


def draw_hero()
	var x = hero.pos.x * CELL_SIZE
    var y = hero.pos.y * CELL_SIZE
    var alarm = int(TileID ALARM3)
    enable_alpha_blend()
    if game.mines > 0
        if game.mines == 1
            alarm = int(TileID ALARM1)
        elif game.mines == 2
            alarm = int(TileID ALARM2)
        tiles[alarm] |> draw_image(x + X_OFF, y + Y_OFF)
    else
        tiles[int(TileID SHADOW)] |> draw_image(x + X_OFF, y + Y_OFF)
	hero.img[int(hero.dir)] |> draw_image(x + X_OFF, y + Y_OFF)
	disable_alpha_blend()
    if game.mines > 0
        set_font_size(12)
        text_out(x + X_OFF, y + Y_OFF, "{game.mines}", 0x000000)
        set_font_size(16)

def check_hero_steps()
    var i = 0
    game.mines = 0
    for h in range(hero.pos.y - 1, hero.pos.y + 2)
        for w in range(hero.pos.x - 1, hero.pos.x + 2)
            i = level[h][w]
            if i == 2
                game.mines += 1
    hero.steps -= 1
    if hero.steps <= 0
        hero.steps = HERO_STEPS_PER_HP
        do_event("hp", -1)

def move_hero_up()
    if hero.dir != DirID UP
        hero.dir = DirID UP
        return
    game.item_pos = int2(hero.pos.y - 1, hero.pos.x)
    if key_exists(items, game.item_pos)
        game.loot_id = items[game.item_pos].loot_id
        if game.loot_id != LootID NONE
            game.state = StateID LOOT
        game.puzzle_id = items[game.item_pos].puzzle_id
        if game.puzzle_id != PuzzleID NONE
            game.state = StateID PUZZLE
        if int(game.story_id) + 1 == int(items[game.item_pos].story_id)
            game.story_id = items[game.item_pos].story_id
            game.story_txt <- split(story[int(game.story_id)], ";")
            game.state = StateID STORY
        if items[game.item_pos].passable
            hero.pos.x = game.item_pos.y
            hero.pos.y = game.item_pos.x
            check_hero_steps()
        if items[game.item_pos].event != ""
            do_event(items[game.item_pos].event, items[game.item_pos].value)
    else
        if level[hero.pos.y - 1][hero.pos.x] == 0
            hero.pos.y -= 1
            check_hero_steps()
        elif level[hero.pos.y - 1][hero.pos.x] == 2
            hero.pos.y -= 1
            do_event("hp", MINE_DAMAGE)
            check_hero_steps()
        elif level[hero.pos.y - 1][hero.pos.x] == 3
            hero.pos.y -= 1
            check_hero_steps()

def move_hero_down()
    if hero.dir != DirID DOWN
        hero.dir = DirID DOWN
        return
    game.item_pos = int2(hero.pos.y + 1, hero.pos.x)
    if key_exists(items, game.item_pos)
        game.loot_id = items[game.item_pos].loot_id
        if game.loot_id != LootID NONE
            game.state = StateID LOOT
        game.puzzle_id = items[game.item_pos].puzzle_id
        if game.puzzle_id != PuzzleID NONE
            game.state = StateID PUZZLE
        if int(game.story_id) + 1 == int(items[game.item_pos].story_id)
            game.story_id = items[game.item_pos].story_id
            game.story_txt <- split(story[int(game.story_id)], ";")
            game.state = StateID STORY
        if items[game.item_pos].passable
            hero.pos.x = game.item_pos.y
            hero.pos.y = game.item_pos.x
            check_hero_steps()
        if items[game.item_pos].event != ""
            do_event(items[game.item_pos].event, items[game.item_pos].value)
    else
        if level[hero.pos.y + 1][hero.pos.x] == 0
            hero.pos.y += 1
            check_hero_steps()
        elif level[hero.pos.y + 1][hero.pos.x] == 2
            hero.pos.y += 1
            do_event("hp", MINE_DAMAGE)
            check_hero_steps()
        elif level[hero.pos.y + 1][hero.pos.x] == 3
            hero.pos.y += 1
            check_hero_steps()

def move_hero_left()
    if hero.dir != DirID LEFT
        hero.dir = DirID LEFT
        return
    game.item_pos = int2(hero.pos.y, hero.pos.x - 1)
    if key_exists(items, game.item_pos)
        game.loot_id = items[game.item_pos].loot_id
        if game.loot_id != LootID NONE
            game.state = StateID LOOT
        game.puzzle_id = items[game.item_pos].puzzle_id
        if game.puzzle_id != PuzzleID NONE
            game.state = StateID PUZZLE
        if int(game.story_id) + 1 == int(items[game.item_pos].story_id)
            game.story_id = items[game.item_pos].story_id
            game.story_txt <- split(story[int(game.story_id)], ";")
            game.state = StateID STORY
        if items[game.item_pos].passable
            hero.pos.x = game.item_pos.y
            hero.pos.y = game.item_pos.x
            check_hero_steps()
        if items[game.item_pos].event != ""
            do_event(items[game.item_pos].event, items[game.item_pos].value)
    else
        if level[hero.pos.y][hero.pos.x - 1] == 0
            hero.pos.x -= 1
            check_hero_steps()
        elif level[hero.pos.y][hero.pos.x - 1] == 2
            hero.pos.x -= 1
            do_event("hp", MINE_DAMAGE)
            check_hero_steps()
        elif level[hero.pos.y][hero.pos.x - 1] == 3
            hero.pos.x -= 1
            check_hero_steps()

def move_hero_right()
    if hero.dir != DirID RIGHT
        hero.dir = DirID RIGHT
        return
    game.item_pos = int2(hero.pos.y, hero.pos.x + 1)
    if key_exists(items, game.item_pos)
        game.loot_id = items[game.item_pos].loot_id
        if game.loot_id != LootID NONE
            game.state = StateID LOOT
        game.puzzle_id = items[game.item_pos].puzzle_id
        if game.puzzle_id != PuzzleID NONE
            game.state = StateID PUZZLE
        if int(game.story_id) + 1 == int(items[game.item_pos].story_id)
            game.story_id = items[game.item_pos].story_id
            game.story_txt <- split(story[int(game.story_id)], ";")
            game.state = StateID STORY
        if items[game.item_pos].passable
            hero.pos.x = game.item_pos.y
            hero.pos.y = game.item_pos.x
            check_hero_steps()
        if items[game.item_pos].event != ""
            do_event(items[game.item_pos].event, items[game.item_pos].value)
    else
        if level[hero.pos.y][hero.pos.x + 1] == 0
            hero.pos.x += 1
            check_hero_steps()
        elif level[hero.pos.y][hero.pos.x + 1] == 2
            hero.pos.x += 1
            do_event("hp", MINE_DAMAGE)
            check_hero_steps()
        elif level[hero.pos.y][hero.pos.x + 1] == 3
            hero.pos.x += 1
            check_hero_steps()

def check_pd()
    var item_pos = int2(0, 0)
    if game.level == 3
        item_pos = int2(6, 10)
        if key_exists(items, item_pos) && items[item_pos].tid == ItemID BLOCK
            items[int2(7, 12)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(7, 12)].passable = true
            items[int2(7, 13)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(7, 13)].passable = true
        else
            items[int2(7, 12)].img = tiles[int(TileID DOORLOCK)]
            items[int2(7, 12)].passable = false
            items[int2(7, 13)].img = tiles[int(TileID DOORLOCK)]
            items[int2(7, 13)].passable = false
    if game.level == 6
        item_pos = int2(8, 9)
        if key_exists(items, item_pos) && items[item_pos].tid == ItemID BLOCK
            items[int2(6, 10)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(6, 10)].passable = true
            items[int2(7, 10)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(7, 10)].passable = true
            items[int2(8, 10)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(8, 10)].passable = true
        else
            items[int2(6, 10)].img = tiles[int(TileID DOORLOCK)]
            items[int2(6, 10)].passable = false
            items[int2(7, 10)].img = tiles[int(TileID DOORLOCK)]
            items[int2(7, 10)].passable = false
            items[int2(8, 10)].img = tiles[int(TileID DOORLOCK)]
            items[int2(8, 10)].passable = false
        item_pos = int2(6, 13)
        if key_exists(items, item_pos) && items[item_pos].tid == ItemID BLOCK
            items[int2(6, 14)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(6, 14)].passable = true
            items[int2(7, 14)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(7, 14)].passable = true
            items[int2(8, 14)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(8, 14)].passable = true
        else
            items[int2(6, 14)].img = tiles[int(TileID DOORLOCK)]
            items[int2(6, 14)].passable = false
            items[int2(7, 14)].img = tiles[int(TileID DOORLOCK)]
            items[int2(7, 14)].passable = false
            items[int2(8, 14)].img = tiles[int(TileID DOORLOCK)]
            items[int2(8, 14)].passable = false
        item_pos = int2(9, 17)
        if key_exists(items, item_pos) && items[item_pos].tid == ItemID BLOCK
            items[int2(6, 18)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(6, 18)].passable = true
            items[int2(7, 18)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(7, 18)].passable = true
            items[int2(8, 18)].img = tiles[int(TileID DOORUNLOCK)]
            items[int2(8, 18)].passable = true
        else
            items[int2(6, 18)].img = tiles[int(TileID DOORLOCK)]
            items[int2(6, 18)].passable = false
            items[int2(7, 18)].img = tiles[int(TileID DOORLOCK)]
            items[int2(7, 18)].passable = false
            items[int2(8, 18)].img = tiles[int(TileID DOORLOCK)]
            items[int2(8, 18)].passable = false

def use_itty()
    var i = 0
    var x, y = 0
    var r, item_pos = int2(HPOS, HPOS)
    game.nn |> clear()
    game.mm |> clear()
    
    if !hero.itty
        return
        
    if hero.kate
        return
    
    if hero.dir == DirID UP
        //y -= ITTY_MAX_RANGE
        game.nn <- [{for y in range(0, ITTY_MAX_RANGE); int2(hero.pos.x, hero.pos.y - y - 1)}]
    elif hero.dir == DirID DOWN
        //y += ITTY_MAX_RANGE
        game.nn <- [{for y in range(0, ITTY_MAX_RANGE); int2(hero.pos.x, hero.pos.y + y + 1)}]
    elif hero.dir == DirID LEFT
        //x -= ITTY_MAX_RANGE
        game.nn <- [{for x in range(0, ITTY_MAX_RANGE); int2(hero.pos.x - x - 1, hero.pos.y)}]
    elif hero.dir == DirID RIGHT
        //x += ITTY_MAX_RANGE
        game.nn <- [{for x in range(0, ITTY_MAX_RANGE); int2(hero.pos.x + x + 1, hero.pos.y)}]
    if hero.carry
        var tmp_pos = item_pos //int2(HPOS, HPOS)
        for r in game.nn
   			if r.x < 0 || r.y < 0 || r.x > CELL_WIDTH - 1 || r.y > CELL_HEIGHT - 1
                break
            i = level[r.y][r.x] //h,w
            if i == 1
                //play_sfx(SfxID ITTY_REFUSE)
                break
            if key_exists(items, int2(r.y, r.x))
                if !items[int2(r.y, r.x)].passable
                    //play_sfx(SfxID ITTY_REFUSE)
                    break
                var item_old := items[int2(r.y, r.x)]
                items_rc[int2(r.y, r.x)] = item_old
            tmp_pos = int2(r.y, r.x)
        item_pos = tmp_pos
        if item_pos != int2(HPOS, HPOS)
            //item_pos = int2(0, 0)
            var item := items[int2(HPOS, HPOS)]
            erase(items, int2(HPOS, HPOS))
            //item_pos = int2(r.y, r.x)
            items[item_pos] = item
            if item.tid == ItemID FLOWIE
                hero.flowie = false
            hero.carry = false
            //play_sfx(SfxID ITTY)
            sfx[int(SfxID ITTY)] |> play_sound()
        do_event("energy", -1)
        check_pd()
    else
        for r in game.nn
			if r.x < 0 || r.y < 0 || r.x > CELL_WIDTH - 1 || r.y > CELL_HEIGHT - 1
				break
            i = level[r.y][r.x] //h,w
            item_pos = int2(r.y, r.x)
            game.mm |> push("{i}:{r.y},{r.x}")
            if (i == 0 || i == 2 || i == 3) && key_exists(items, item_pos)
                if items[item_pos].ittable
                    var item := items[item_pos]
                    erase(items, item_pos)
                    if key_exists(items_rc, item_pos)
                        var item_old := items_rc[item_pos]
                        items[item_pos] = item_old
                    item_pos = int2(HPOS, HPOS)//CELL_WIDTH)
                    items[item_pos] = item
                    hero.carry = true
                    //play_sfx(SfxID ITTY)
                    sfx[int(SfxID ITTY)] |> play_sound()
                    if item.tid == ItemID FLOWIE
                        hero.flowie = true
                    elif item.tid == ItemID KATE
                        hero.kate = true
                        do_event("electrokate", 1)
                    break
        do_event("energy", -1)
        check_pd()

// QUESTS

def ok_quest()
    game.quest_txt = quest[int(game.story_id)]
    game.state = StateID GAME
    
def draw_quest()
    var pos = int2(0, 0)
	enable_alpha_blend()
    fill_rect(pos.x, pos.y, WIDTH, HEIGHT, BACKGROUND_FADE_COLOR)
    disable_alpha_blend()
    pos = int2(0, HEIGHT_D3)
    fill_rect(pos.x, pos.y, WIDTH, HEIGHT_D3, BACKGROUND_COLOR)
    pos = int2(WIDTH_D3, HEIGHT_D3 + 20)
    text_out(pos.x, pos.y, "NEW QUEST\n\n{quest[int(game.story_id)]}", 0x00FFFF)
    pos.y = HEIGHT_D3 + HEIGHT_D3 - 40
    text_out(pos.x, pos.y, "Press [ENTER] to continue.", 0x00FFFF)

def ok_story()
    if game.story_page < (length(game.story_txt) - 1)
        game.story_page += 1
        game.story_ava += 1
        if game.story_ava > 1
            game.story_ava = 0
    else
        game.story_page = 0
        game.story_ava = 0
        game.story_txt |> clear()
        game.state = StateID QUEST
    
def draw_story()
    var pos = int2(0, 0)
	enable_alpha_blend()
    fill_rect(pos.x, pos.y, WIDTH, HEIGHT, BACKGROUND_FADE_COLOR)
    disable_alpha_blend()
    pos = int2(0, HEIGHT_D3)
    fill_rect(pos.x, pos.y, WIDTH, HEIGHT_D3, STORY_BACKGROUND_COLOR)
    pos = int2(WIDTH_D3 - 150, HEIGHT_D3 + 20)
    avatars[game.story_ava] |> draw_image(pos.x, pos.y)
    pos = int2(WIDTH_D3, HEIGHT_D3 + 20)
    text_out(pos.x, pos.y, "{game.story_txt[game.story_page]}", 0x00FFFF)
    pos.y = HEIGHT_D3 + HEIGHT_D3 - 40
    text_out(pos.x, pos.y, "({game.story_page + 1}/{length(game.story_txt)}) Press [ENTER] to continue.", 0x00FFFF)

def ok_loot()
    var loot = loots[int(game.loot_id)]
    var event = loot.event
    var value = loot.value
    items[game.item_pos].loot_id = LootID EMPTY
    game.loot_id = LootID EMPTY
    game.state = StateID GAME
    do_event(event, value)

def draw_loot()
    var loot = loots[int(game.loot_id)]
    var pos = int2(0, 0)
    var txt = "Press [ENTER] to take."
    if game.loot_id == LootID EMPTY
        txt = "Press [ENTER] to close."
	enable_alpha_blend()
    fill_rect(pos.x, pos.y, WIDTH, HEIGHT, BACKGROUND_FADE_COLOR)
    disable_alpha_blend()
    pos = int2(0, HEIGHT_D3)
    fill_rect(pos.x, pos.y, WIDTH, HEIGHT_D3, BACKGROUND_COLOR)
    pos = int2(WIDTH_D3 - 150, HEIGHT_D3 + 20)
    loot.img |> draw_image(pos.x, pos.y)
    pos = int2(WIDTH_D3 + 20, HEIGHT_D3 + 20)
    text_out(pos.x, pos.y, "{loot.name}\n\n{loot.data}\n", 0x00FFFF)
    pos.y = HEIGHT_D3 + HEIGHT_D3 - 40
    text_out(pos.x, pos.y, txt, 0x00FFFF)
    
def draw_win()
    var pos = int2(0, 0)
	enable_alpha_blend()
    fill_rect(pos.x, pos.y, WIDTH, HEIGHT, BACKGROUND_FADE_COLOR)
    disable_alpha_blend()
    pos = int2(0, HEIGHT_D3)
    fill_rect(pos.x, pos.y, WIDTH, HEIGHT_D3, BACKGROUND_COLOR)
    pos = int2(WIDTH_D3 - 150, HEIGHT_D3 + 20)
    gui[int(GuiID VICTORY)] |> draw_image(pos.x, pos.y)
    pos = int2(WIDTH_D3, HEIGHT_D3 + 20)
    text_out(pos.x, pos.y, "VICTORY!\n\nKate re-booted the mainframe PC. All systems work fine now.\n937 colonists are alive. The spaceship is on the course.\nAlex transfered Kate to the medical deck where she was\nre-integrated back to a human form. Flowey is growing...", 0x00FFFF)
    pos.y = HEIGHT_D3 + HEIGHT_D3 - 40
    text_out(pos.x, pos.y, "Press [Enter] to go to menu.", 0x00FFFF)

def draw_fail()
    var pos = int2(0, 0)
	enable_alpha_blend()
    fill_rect(pos.x, pos.y, WIDTH, HEIGHT, BACKGROUND_FADE_COLOR)
    disable_alpha_blend()
    pos = int2(0, HEIGHT_D3)
    fill_rect(pos.x, pos.y, WIDTH, HEIGHT_D3, BACKGROUND_COLOR)
    pos = int2(WIDTH_D3 - 150, HEIGHT_D3 + 20)
    gui[int(GuiID DEFEAT)] |> draw_image(pos.x, pos.y)
    pos = int2(WIDTH_D3, HEIGHT_D3 + 20)
    text_out(pos.x, pos.y, "DEFEAT!\n\nControl you HP level and amount of energy in ITTy.\nAvoid electro-magnetic mines.\n", 0x00FFFF)
    pos.y = HEIGHT_D3 + HEIGHT_D3 - 40
    text_out(pos.x, pos.y, "Press [Enter] to go to menu.", 0x00FFFF)

// PUZZLE //

//def move_puzzle_up()
//    return

//def move_puzzle_down()
//    return

//def move_puzzle_left()
//    return

//def move_puzzle_right()
//    return

def check_puzzle()
    var n = 0   
    for i in range(0, 9)
        n += puzzles[int(game.puzzle_id)].data[i]
    if n == 0
        return true
    else
        return false

def rotate_puzzle(i: int)
    var angle = 0
    angle = puzzles[int(game.puzzle_id)].data[i - 1]
    if angle == 0
        angle = 90
    elif angle == 90
        angle = 180
    elif angle == 180
        angle = 270
    elif angle == 270
        angle = 0
    puzzles[int(game.puzzle_id)].data[i - 1] = angle
        

def ok_puzzle()
    if check_puzzle()
        do_event("da4", 1)
    else
        game.state = StateID GAME

def draw_puzzle()
    var pos = int2(0, 0)
    var x, y, tx, ty = 0
    var txt = "Press [1]-[9] to rotate sections\nPress [ENTER] to close."
    var tex = float4(0, 0, 0, 0)
    var wh = float2(86, 86)
    var angle = 0
	enable_alpha_blend()
    fill_rect(pos.x, pos.y, WIDTH, HEIGHT, BACKGROUND_FADE_COLOR)
    disable_alpha_blend()
    pos = int2(WIDTH_D2 - HEIGHT_D4, HEIGHT_D2 - HEIGHT_D4)
    fill_rect(pos.x, pos.y, HEIGHT_D2, HEIGHT_D2, PUZZLE_BACKGROUND_COLOR)
    //TODO: optimize this piece of g-code
    pos.x += 51 + 43
    pos.y += 51 + 43
    x = pos.x
    y = pos.y
    ty = 0
    for i in range(0, 3)
        pos.x = x + i * 86
        tx = i * 86
        tex = float4(tx, ty, 86, 86)
        angle = puzzles[int(game.puzzle_id)].data[i]
        puzzles[int(game.puzzle_id)].img |> draw_image_transformed(float(pos.x), float(pos.y), tex, 0xFFFFFFFF, wh, RAD[angle], 0.5, 0.5)
    pos.y += 86
    ty += 86
    for i in range(0, 3)
        pos.x = x + i * 86
        tx = i * 86
        tex = float4(tx, ty, 86, 86)
        angle = puzzles[int(game.puzzle_id)].data[i + 3]
        puzzles[int(game.puzzle_id)].img |> draw_image_transformed(float(pos.x), float(pos.y), tex, 0xFFFFFFFF, wh, RAD[angle], 0.5, 0.5)
    pos.y += 86
    ty += 86
    for i in range(0, 3)
        pos.x = x + i * 86
        tx = i * 86
        tex = float4(tx, ty, 86, 86)
        angle = puzzles[int(game.puzzle_id)].data[i + 6]
        puzzles[int(game.puzzle_id)].img |> draw_image_transformed(float(pos.x), float(pos.y), tex, 0xFFFFFFFF, wh, RAD[angle], 0.5, 0.5)
    pos = int2(WIDTH_D2 - HEIGHT_D4 + 20, HEIGHT - HEIGHT_D4)    
    text_out(pos.x, pos.y, txt, 0x00FFFF)

// LOCK //

//def draw_lock()
//    return

// LEVEL //

def init_levels()
    //TILES
    tiles |> resize(int(TileID DUMMY))
    tiles[int(TileID FLOOR)] <- create_managed_image("assets/game/tiles/floor.png")
    tiles[int(TileID WALL)] <- create_managed_image("assets/game/tiles/wall.png")
    tiles[int(TileID MINE)] <- create_managed_image("assets/game/tiles/floor.png")
    tiles[int(TileID PD)] <- create_managed_image("assets/game/tiles/pd.png")
    tiles[int(TileID BLOCK)] <- create_managed_image("assets/game/tiles/block.png")
    tiles[int(TileID WALL_UP)] <- create_managed_image("assets/game/tiles/wall_up.png")
    tiles[int(TileID WALL_DOWN)] <- create_managed_image("assets/game/tiles/wall_down.png")
    tiles[int(TileID WALL_FLOOR)] <- create_managed_image("assets/game/tiles/wall_floor.png")
    tiles[int(TileID WALL_ROCKS)] <- create_managed_image("assets/game/tiles/wall_rocks.png")
    tiles[int(TileID DOORLOCK)] <- create_managed_image("assets/game/tiles/doorlock.png")
    tiles[int(TileID DOORUNLOCK)] <- create_managed_image("assets/game/tiles/doorunlock.png")
    tiles[int(TileID DOORLOCK2)] <- create_managed_image("assets/game/tiles/doorlock2.png")
    tiles[int(TileID DOORUNLOCK2)] <- create_managed_image("assets/game/tiles/doorunlock2.png")
    tiles[int(TileID CP)] <- create_managed_image("assets/game/tiles/cp.png")
    tiles[int(TileID PC)] <- create_managed_image("assets/game/tiles/pc.png")
    tiles[int(TileID CORPSE)] <- create_managed_image("assets/game/tiles/corpse.png")
    tiles[int(TileID LOOTBOX)] <- create_managed_image("assets/game/tiles/lootbox.png")
    tiles[int(TileID DA2)] <- create_managed_image("assets/game/tiles/decka2.png")
    tiles[int(TileID DA3)] <- create_managed_image("assets/game/tiles/decka3.png")
    tiles[int(TileID DA4)] <- create_managed_image("assets/game/tiles/decka4.png")
    tiles[int(TileID DA4L)] <- create_managed_image("assets/game/tiles/decka4l.png")
    tiles[int(TileID DA4R)] <- create_managed_image("assets/game/tiles/decka4r.png")
    tiles[int(TileID DA5)] <- create_managed_image("assets/game/tiles/decka5.png")
    tiles[int(TileID DA5L)] <- create_managed_image("assets/game/tiles/decka5l.png")
    tiles[int(TileID DA6L)] <- create_managed_image("assets/game/tiles/decka6l.png")
    tiles[int(TileID DA6)] <- create_managed_image("assets/game/tiles/decka6.png")
    tiles[int(TileID SHADOW)] <- create_managed_image("assets/game/tiles/shadow.png")
    tiles[int(TileID ALARM1)] <- create_managed_image("assets/game/tiles/alarm1.png")
    tiles[int(TileID ALARM2)] <- create_managed_image("assets/game/tiles/alarm2.png")
    tiles[int(TileID ALARM3)] <- create_managed_image("assets/game/tiles/alarm3.png")
    tiles[int(TileID DAMAGE)] <- create_managed_image("assets/game/tiles/damage.png")
    tiles[int(TileID FLOWIE)] <- create_managed_image("assets/game/tiles/flowie.png")
    tiles[int(TileID KATE)] <- create_managed_image("assets/game/tiles/kate.png")
    //STORY
    push(avatars, create_managed_image("assets/game/story/kate.png"))
    push(avatars, create_managed_image("assets/game/story/alex.png"))
    story |> resize(int(StoryID DUMMY))
    story[int(StoryID NONE)] = "None"
    story[int(StoryID START)] = "Kate:\n\nAlex! I'm here!;Alex:\n\nKate, what's happened?!;Kate:\n\nI don't know. The crew is dead. The ship is damaged.\nThe security system is out of control.;Alex:\n\nCan you move?;Kate:\n\nNo.;Alex:\n\nWait, I will try to help you.;Kate:\n\nNo, the armature is too heavy. Besides, just look at\nmy wounds. I can't last it too long. Save yourself!;Alex:\n\nNo way! I won't let you die here..."
    story[int(StoryID ITTY)] = "Kate:\n\nLeave me, Alex. Save yourself!;Alex:\n\nWait. I have an idea! Honey, where is my ITTy?;Kate:\n\nYour what?!;Alex:\n\nMy ITTy -- an Item Teleportation Tool. My latest\ninvention. Not well-tested, though...;Kate:\n\nA metal glove emitting blue rays? Is that thing?;Alex:\n\nExactly! Where is it?;Kate:\n\nI think I saw it put on Max, our technician. Would\nyou check those corpses. One of them should be Max."
    story[int(StoryID ELECTROKATE)] = "Kate:\n\nAlex?;Alex:\n\nKate! I found it! Now, don't move!"
    story[int(StoryID UPLOAD)] = "Kate:\n\n???;Alex:\n\nHoney, don't worry. You're energy form of life now.;Kate:\n\n???;Alex:\n\nLet me release you into the spaceship's power system\nto see what happens."
    story[int(StoryID DECKA2)] = "Kate:\n\nAlex!;Alex:\n\nKate! How are you feeling yourself?;Kate:\n\nA bit weird. Unusual. As a strange form of\nlife. But I'm here and I'm still alive.;Alex:\n\nOh, honey...;Kate:\n\nI have connected to INTERCOM. I see you and\nI can speak with you.;Alex:\n\nCan your re-boot the spaceship's operating system?;Kate:\n\nNot from here. You need to go to the captain's\nbridge and give me access to the system manually.\nI'm opening the door for you... Go forward!"
    //
    story[int(StoryID GETSOMELOOT)] = "Kate:\n\nAlex, you need something to eat to keep walking\nand your ITTy needs power supply.;Alex:\n\nYou're right. Every my step takes my energy\nquite fast.;Kate:\n\nThe broken AI is changing oxygen and gravity\nparameters on the spaceship.;Alex:\n\nThat's bad news. Need to move on..."
    story[int(StoryID FLOWIE)] = "Kate:\n\nAlex, don't forget my Flowey. You know, this is\nthe only thing I love on this spaceship.\nWell, except you...;Alex:\n\nHoney, I don't have any pockets for your plant.;Kate:\n\nIt's not a plant! It's Flowey!;Alex:\n\nAlright, alright. But I really need to keep\nmy hands free on the way to the captain's bridge.;Kate:\n\nWould you carry Flowey with your ITTy all the way?;Alex:\n\nKate, you're so smart..."
    story[int(StoryID DECKA3)] = "Kate:\n\nAlex, all the doors on the spaceship have been\nblocked by the security system.;Alex:\n\nCan you get an access to the door to Deck A3?;Kate:\n\nYes. I've just opened it for you."
    //
    story[int(StoryID PRESSURE1)] = "Kate:\n\nAlex, I couldn't open the door in front of you.;Alex:\n\nWhat we're going to do then?;Kate:\n\nThere is a pressure detector near the door. You need\nto put something heavy on it to make it work.;Alex:\n\nI'd put Flowey on it to see what happens.;Kate:\n\nAlex!;Alex:\n\nAlright, alright. It's not heavy enough for a pressure\ndetector. I need to put a box or a block on it."
    story[int(StoryID DECKA4)] = "Kate:\n\nAlex, you did it! I've also opened the door\nto Deck A4. Keep moving.;Alex:\n\nThanks, honey."
    //
    story[int(StoryID MINEFIELD)] = "Kate:\n\nThe broken AI already located my presence\nin the system and activated an intrusion protocol.;Alex:\n\nIt sounds not good for us, right?;Kate:\n\nIndeed. It's trying to avoid my interlocks.\nAnd...;Alex:\n\nWhat else, Kate?;Kate:\n\nThere are electro-magnetic mines under\nthe floor. And the mines were set to armed.;Alex:\n\nSo, the floor now is like...;Kate:\n\nA minefield, yes. Please, watch your step, Alex!;Alex:\n\nWell, I'm not sure will I pass few meters more.;Kate:\n\nI'm still able to locate mines around you\nand I'm sending this data on your personal HUD.;Alex:\n\nThanks, honey."
    story[int(StoryID CP1)] = "Kate:\n\nGood news, Alex! It seems 937 colonists are\nstill alive, in anabiosis pods on Deck A5.;Alex:\n\nAlright! We're near the captain's bridge.;Kate:\n\nThe bad news -- we can't go through. Otherwise\nthe AI could destroy the pods. Need to find a way around.;Alex:\n\nYour suggestions?;Kate:\n\nThe corridor on the right is sealed. Go\nto the corridor on the left, Deck A4L.;Alex:\n\nOk, I will.;Kate:\n\nThere is more. You need to activate Control\nPanel to give me access to open the door to Deck A4L."
    story[int(StoryID DECKA4L)] = "Kate:\n\nAlex, you're good! The door to Deck A4L is open.\nKeep moving.;Alex:\n\nThanks, honey."
    //
    story[int(StoryID DECKA5L)] = "Kate:\n\nEverything seems clear. Avoid mines and keep moving.;Alex:\n\nI'm on my way!"
    //
    story[int(StoryID PRESSURE2)] = "Kate:\n\nI see no mines, but the doors are locked.\nThere are few pressure detectors. You know what to do.;Alex:\n\nYep!"
    story[int(StoryID DECKA6L)] = "Kate:\n\nThe path is clear.;Alex:\n\nThanks, honey."
    //
    story[int(StoryID DECKA6)] = "Kate:\n\nEverything seems clear. Avoid mines and keep moving.;Alex:\n\nAlright!"
    //
    story[int(StoryID END)] = "Kate:\n\nAlex! We're on the captain's bridge! Give me access\nto the system to re-boot it.;Alex:\n\nOn my way, honey. Just one thing -- Kate, back up\nyourself somewhere..."
    //
    story[int(StoryID DONTFORGETFLOWIE)] = "Kate:\n\nAlex! Don't forget Flowey!;Alex:\n\nAlright, alright..."
    //QUEST
    quest |> resize(int(StoryID DUMMY))
    quest[int(StoryID NONE)] = "None"
    quest[int(StoryID START)] = "Look around and figure out how to save Kate"
    quest[int(StoryID ITTY)] = "Search dead corpses to find ITTy"
    quest[int(StoryID ELECTROKATE)] = "Stand in front of Kate and disintegrate your wife with ITTy"
    quest[int(StoryID UPLOAD)] = "Go to mainframe PC and release Kate into the power system"
    quest[int(StoryID DECKA2)] = "Go to Deck A2"
    quest[int(StoryID GETSOMELOOT)] = "Search dead corpses and boxes for some loot to use"
    quest[int(StoryID FLOWIE)] = "Find Flowey (the plant) and keep carrying it with ITTy all the way"
    quest[int(StoryID DECKA3)] = "Go to Deck A3"
    quest[int(StoryID PRESSURE1)] = "Put some heavy box on a pressure detector to open the door"
    quest[int(StoryID DECKA4)] = "Go to Deck A4"
    quest[int(StoryID MINEFIELD)] = "Pass through the minefield"
    quest[int(StoryID CP1)] = "Activate Control Panel on the wall near the door to Deck A4L"
    quest[int(StoryID DECKA4L)] = "Go to Deck A4L"
    quest[int(StoryID DECKA5L)] = "Go to Deck A5L"
    quest[int(StoryID PRESSURE2)] = "Open the inner doors by activating pressure detectors"
    quest[int(StoryID DECKA6L)] = "Go to Deck A6L"
    quest[int(StoryID DECKA6)] = "Go to Deck A6 (the captain's brdge)"
    quest[int(StoryID END)] = "Go to mainframe PC and give access to Kate to re-boot the system"
    quest[int(StoryID DONTFORGETFLOWIE)] = "Get Flowey back"
    //LOOT
    loots |> resize(int(LootID DUMMY))
    //loots[int(LootID NONE)].img <- create_managed_image("assets/game/loot/empty.png")
    loots[int(LootID NONE)].name = "None"
    loots[int(LootID NONE)].data = "It's none"
    loots[int(LootID EMPTY)].img <- create_managed_image("assets/game/loot/empty.png")
    loots[int(LootID EMPTY)].name = "Empty"
    loots[int(LootID EMPTY)].data = "Nothing's interesting"
    loots[int(LootID ITTY)].img <- create_managed_image("assets/game/loot/itty.png")
    loots[int(LootID ITTY)].name = "ITTy"
    loots[int(LootID ITTY)].data = "Item Teleportation Tool, a device to teleport\nobjects on a distance"
    loots[int(LootID ITTY)].value = 1
    loots[int(LootID ITTY)].event = "itty"
    //
    loots[int(LootID WATER)].img <- create_managed_image("assets/game/loot/water.png")
    loots[int(LootID WATER)].name = "Water"
    loots[int(LootID WATER)].data = "A bottle of water, +1 to health"
    loots[int(LootID WATER)].value = 1
    loots[int(LootID WATER)].event = "hp"
    loots[int(LootID WATER_X2)].img <- create_managed_image("assets/game/loot/water_x2.png")
    loots[int(LootID WATER_X2)].name = "Water"
    loots[int(LootID WATER_X2)].data = "Two bottles of water, +2 to health"
    loots[int(LootID WATER_X2)].value = 2
    loots[int(LootID WATER_X2)].event = "hp"
    loots[int(LootID JUICE)].img <- create_managed_image("assets/game/loot/juice.png")
    loots[int(LootID JUICE)].name = "Juice"
    loots[int(LootID JUICE)].data = "A bottle of cherry juice, +2 to health"
    loots[int(LootID JUICE)].value = 2
    loots[int(LootID JUICE)].event = "hp"
    loots[int(LootID BAR)].img <- create_managed_image("assets/game/loot/bar.png")
    loots[int(LootID BAR)].name = "Bar"
    loots[int(LootID BAR)].data = "A protein bar, +1 to health"
    loots[int(LootID BAR)].value = 1
    loots[int(LootID BAR)].event = "hp"
    loots[int(LootID BAR_X2)].img <- create_managed_image("assets/game/loot/bar_x2.png")
    loots[int(LootID BAR_X2)].name = "Bar"
    loots[int(LootID BAR_X2)].data = "Two protein bars, +2 to health"
    loots[int(LootID BAR_X2)].value = 2
    loots[int(LootID BAR_X2)].event = "hp"
    loots[int(LootID TOMATO)].img <- create_managed_image("assets/game/loot/tomato.png")
    loots[int(LootID TOMATO)].name = "Tomato"
    loots[int(LootID TOMATO)].data = "A can of dried tomatos, +2 to health"
    loots[int(LootID TOMATO)].value = 2
    loots[int(LootID TOMATO)].event = "hp"
    loots[int(LootID PEANUTS)].img <- create_managed_image("assets/game/loot/peanuts.png")
    loots[int(LootID PEANUTS)].name = "Peanuts"
    loots[int(LootID PEANUTS)].data = "A pack of dried peanuts, +2 to health"
    loots[int(LootID PEANUTS)].value = 2
    loots[int(LootID PEANUTS)].event = "hp"
    loots[int(LootID BREAD)].img <- create_managed_image("assets/game/loot/bread.png")
    loots[int(LootID BREAD)].name = "Bread"
    loots[int(LootID BREAD)].data = "A large piece of bread, +3 to health"
    loots[int(LootID BREAD)].value = 3
    loots[int(LootID BREAD)].event = "hp"
    loots[int(LootID CHOCOLATE)].img <- create_managed_image("assets/game/loot/chocolate.png")
    loots[int(LootID CHOCOLATE)].name = "Chocolate"
    loots[int(LootID CHOCOLATE)].data = "A chocolate bar, +1 to health"
    loots[int(LootID CHOCOLATE)].value = 1
    loots[int(LootID CHOCOLATE)].event = "hp"
    //
    loots[int(LootID SODA)].img <- create_managed_image("assets/game/loot/soda.png")
    loots[int(LootID SODA)].name = "Soda"
    loots[int(LootID SODA)].data = "A can of sweet soda, -1 to health"
    loots[int(LootID SODA)].value = -1
    loots[int(LootID SODA)].event = "hp"
    loots[int(LootID CUPCAKE)].img <- create_managed_image("assets/game/loot/cupcake.png")
    loots[int(LootID CUPCAKE)].name = "Cupcake"
    loots[int(LootID CUPCAKE)].data = "A sweet cupcake, -1 to health"
    loots[int(LootID CUPCAKE)].value = -1
    loots[int(LootID CUPCAKE)].event = "hp"
    loots[int(LootID CANDY)].img <- create_managed_image("assets/game/loot/candy.png")
    loots[int(LootID CANDY)].name = "Candy"
    loots[int(LootID CANDY)].data = "A sweet candy, -1 to health"
    loots[int(LootID CANDY)].value = -1
    loots[int(LootID CANDY)].event = "hp"
    //
    loots[int(LootID MEDICINE)].img <- create_managed_image("assets/game/loot/medicine.png")
    loots[int(LootID MEDICINE)].name = "Medicine"
    loots[int(LootID MEDICINE)].data = "A pack of medicine, +2 to health"
    loots[int(LootID MEDICINE)].value = 2
    loots[int(LootID MEDICINE)].event = "hp"
    loots[int(LootID MEDICINE_X2)].img <- create_managed_image("assets/game/loot/medicine_x2.png")
    loots[int(LootID MEDICINE_X2)].name = "Medicine"
    loots[int(LootID MEDICINE_X2)].data = "Two packs of medicine, +4 to health"
    loots[int(LootID MEDICINE_X2)].value = 4
    loots[int(LootID MEDICINE_X2)].event = "hp"
    //
    loots[int(LootID BATTERY)].img <- create_managed_image("assets/game/loot/battery.png")
    loots[int(LootID BATTERY)].name = "Battery"
    loots[int(LootID BATTERY)].data = "A battery for ITTy, +2 to energy"
    loots[int(LootID BATTERY)].value = 2
    loots[int(LootID BATTERY)].event = "energy"
    loots[int(LootID BATTERY_X2)].img <- create_managed_image("assets/game/loot/battery_x2.png")
    loots[int(LootID BATTERY_X2)].name = "Battery"
    loots[int(LootID BATTERY_X2)].data = "Two batteries for ITTy, +4 to energy"
    loots[int(LootID BATTERY_X2)].value = 4
    loots[int(LootID BATTERY_X2)].event = "energy"
    //PUZZLES
    puzzles |> resize(int(PuzzleID DUMMY))
    puzzles[int(PuzzleID P1)].img <- create_managed_image("assets/game/puzzle1.png")
    puzzles[int(PuzzleID P1)].data <- [{ int 0; 90; 0; 180; 0; 270; 0; 90; 0 }]
    
def load_level()

    level |> clear()
    items |> clear()
    items_rc |> clear()
    game.mines = 0

    if game.level == 1
        //LEVEL
        game.level_txt = "Deck A1"
        level[0] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[1] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[2] = [[ int[26] -1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; -1 ]]
        level[3] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; -1; -1 ]]
        level[4] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; -1; -1 ]]
        level[5] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; 1; 1 ]]
        level[6] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 0; 1; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; 0; 0; 0; 0; 1; 1; 1 ]]
        level[7] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 0; 1; 1; 1; 0; 0; 1; 0; 0; 1; 1; 1; 0; 0; 0; 0; 0; 1; 1 ]]
        level[8] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 0; 1; 1; 1; 0; 0; 0; 0; 0; 1; 1; 1; 0; 0; 0; 0; 1; 1; 1 ]]
        level[9] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; 1; 1 ]]
        level[10] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; -1; -1 ]]
        level[11] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; -1; -1 ]]
        level[12] = [[ int[26] -1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; -1 ]]
        level[13] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[14] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        //ITEMS
        items[int2(2, 6)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 7)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 8)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 9)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 10)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 11)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 12)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 13)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 14)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 15)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 16)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 17)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 18)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 19)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 20)].img = tiles[int(TileID WALL_UP)]
        //
        items[int2(3, 6)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 6)].passable = true
        items[int2(3, 7)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 7)].passable = true
        items[int2(3, 8)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 8)].passable = true
        items[int2(3, 9)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 9)].passable = true
        items[int2(3, 10)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 10)].passable = true
        items[int2(3, 11)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 11)].passable = true
        items[int2(3, 12)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 12)].passable = true
        items[int2(3, 13)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 13)].passable = true
        items[int2(3, 14)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 14)].passable = true
        items[int2(3, 15)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 15)].passable = true
        items[int2(3, 16)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 16)].passable = true
        items[int2(3, 17)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 17)].passable = true
        items[int2(3, 18)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 18)].passable = true
        items[int2(3, 19)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 19)].passable = true
        items[int2(3, 20)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 20)].passable = true
        //
        items[int2(6, 9)].img = tiles[int(TileID KATE)]
        items[int2(6, 9)].tid = ItemID KATE
        items[int2(6, 9)].ittable = true
        //
        items[int2(7, 13)].img = tiles[int(TileID PC)]
        items[int2(7, 13)].event = "da1pc"
        //
        items[int2(9, 8)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(9, 8)].passable = true
        items[int2(9, 9)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(9, 9)].passable = true
        items[int2(9, 10)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(9, 10)].passable = true
        items[int2(9, 16)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(9, 16)].passable = true
        items[int2(9, 17)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(9, 17)].passable = true
        items[int2(9, 18)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(9, 18)].passable = true
        //
        items[int2(6, 21)].img = tiles[int(TileID DOORLOCK)]
        items[int2(7, 21)].img = tiles[int(TileID DOORLOCK)]
        items[int2(8, 21)].img = tiles[int(TileID DOORLOCK)]
        //
        items[int2(7, 23)].img = tiles[int(TileID DA2)]
        items[int2(7, 23)].event = "level"
        //
        items[int2(9, 6)].img = tiles[int(TileID CORPSE)]
        items[int2(9, 6)].loot_id = LootID EMPTY
        items[int2(11, 11)].img = tiles[int(TileID CORPSE)]
        items[int2(11, 11)].loot_id = LootID EMPTY
        items[int2(11, 17)].img = tiles[int(TileID CORPSE)]
        items[int2(11, 17)].loot_id = LootID ITTY
        //
        items[int2(3, 12)].story_id = StoryID START
        items[int2(3, 12)].passable = true
        items[int2(3, 14)].story_id = StoryID START
        items[int2(3, 14)].passable = true
        items[int2(4, 12)].story_id = StoryID START
        items[int2(4, 12)].passable = true
        items[int2(4, 13)].story_id = StoryID START
        items[int2(4, 13)].passable = true
        items[int2(4, 14)].story_id = StoryID START
        items[int2(4, 14)].passable = true
        //
        items[int2(3, 11)].story_id = StoryID ITTY
        items[int2(3, 11)].passable = true
        items[int2(3, 15)].story_id = StoryID ITTY
        items[int2(3, 15)].passable = true
        items[int2(4, 11)].story_id = StoryID ITTY
        items[int2(4, 11)].passable = true
        items[int2(4, 15)].story_id = StoryID ITTY
        items[int2(4, 15)].passable = true
        items[int2(5, 11)].story_id = StoryID ITTY
        items[int2(5, 11)].passable = true
        items[int2(5, 12)].story_id = StoryID ITTY
        items[int2(5, 12)].passable = true
        items[int2(5, 13)].story_id = StoryID ITTY
        items[int2(5, 13)].passable = true
        items[int2(5, 14)].story_id = StoryID ITTY
        items[int2(5, 14)].passable = true
        items[int2(5, 15)].story_id = StoryID ITTY
        items[int2(5, 15)].passable = true
        //HERO
        hero.dir = DirID DOWN
        hero.hp = 10
        hero.energy = 5
        hero.itty = false
        hero.kate = false
        hero.flowie = true
        hero.pos = int2(13, 3)
        game.story_id = StoryID NONE
    elif game.level == 2
        //LEVEL
        game.level_txt = "Deck A2"
        level[0] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[1] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[2] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[3] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[4] = [[ int[26] -1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; -1 ]]
        level[5] = [[ int[26] 1; 1; 1; 1; 0; 0; 1; 1; 0; 0; 0; 0; 0; 0; 1; 1; 0; 0; 0; 0; 0; 0; 1; 1; 1; 1 ]]
        level[6] = [[ int[26] 1; 1; 1; 0; 0; 0; 1; 1; 0; 0; 0; 0; 0; 0; 1; 1; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1 ]]
        level[7] = [[ int[26] 1; 1; 0; 0; 0; 0; 1; 1; 0; 0; 1; 1; 0; 0; 1; 1; 0; 0; 1; 1; 0; 0; 0; 0; 1; 1 ]]
        level[8] = [[ int[26] 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 1; 1; 0; 0; 0; 0; 0; 0; 1; 1; 0; 0; 0; 1; 1; 1 ]]
        level[9] = [[ int[26] 1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 1; 1; 0; 0; 0; 0; 0; 0; 1; 1; 0; 0; 1; 1; 1; 1 ]]
        level[10] = [[ int[26] -1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; -1 ]]
        level[11] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[12] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[13] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[14] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        //ITEMS
        items[int2(5, 4)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 4)].passable = true
        items[int2(5, 5)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 5)].passable = true
        items[int2(5, 8)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 8)].passable = true
        items[int2(5, 9)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 9)].passable = true
        items[int2(5, 10)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 10)].passable = true
        items[int2(5, 11)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 11)].passable = true
        items[int2(5, 12)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 12)].passable = true
        items[int2(5, 13)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 13)].passable = true
        items[int2(5, 16)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 16)].passable = true
        items[int2(5, 17)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 17)].passable = true
        items[int2(5, 18)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 18)].passable = true
        items[int2(5, 19)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 19)].passable = true
        items[int2(5, 20)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 20)].passable = true
        items[int2(5, 21)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 21)].passable = true
        //
        items[int2(8, 6)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(8, 6)].passable = true
        items[int2(8, 7)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(8, 7)].passable = true
        items[int2(8, 14)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(8, 14)].passable = true
        items[int2(8, 15)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(8, 15)].passable = true
        //
        items[int2(7, 3)].story_id = StoryID GETSOMELOOT
        items[int2(7, 3)].passable = true
        //
        items[int2(7, 12)].story_id = StoryID FLOWIE
        items[int2(7, 12)].passable = true
        items[int2(7, 13)].story_id = StoryID FLOWIE
        items[int2(7, 13)].passable = true
        //  
        items[int2(5, 20)].story_id = StoryID DECKA3
        items[int2(5, 20)].passable = true
        items[int2(5, 20)].event = "da2"
        //
        items[int2(9, 17)].img = tiles[int(TileID FLOWIE)]
        items[int2(9, 17)].tid = ItemID FLOWIE
        items[int2(9, 17)].ittable = true
        //
        items[int2(6, 22)].img = tiles[int(TileID DOORLOCK)]
        items[int2(7, 22)].img = tiles[int(TileID DOORLOCK)]
        items[int2(8, 22)].img = tiles[int(TileID DOORLOCK)]
        //
        items[int2(7, 23)].img = tiles[int(TileID DA3)]
        items[int2(7, 23)].event = "level"
        //
        items[int2(6, 5)].img = tiles[int(TileID CORPSE)]
        items[int2(6, 5)].loot_id = LootID BAR
        items[int2(9, 12)].img = tiles[int(TileID CORPSE)]
        items[int2(9, 12)].loot_id = LootID BATTERY_X2
        items[int2(9, 9)].img = tiles[int(TileID LOOTBOX)]
        items[int2(9, 9)].loot_id = LootID MEDICINE
        items[int2(6, 19)].img = tiles[int(TileID LOOTBOX)]
        items[int2(6, 19)].loot_id = LootID WATER
        //HERO
        hero.dir = DirID RIGHT
        if hero.hp == 0
            hero.hp = 5
        if hero.energy == 0
            hero.energy = 5
        hero.itty = true
        hero.kate = false
        hero.flowie = false
        hero.pos = int2(2, 7)
        game.story_id = StoryID DECKA2
    elif game.level == 3
        //LEVEL
        game.level_txt = "Deck A3"
        level[0] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[1] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[2] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[3] = [[ int[26] -1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; -1 ]]
        level[4] = [[ int[26] -1; -1; -1; 1; 0; 0; 0; 0; 0; 0; 1; 1; -1; -1; 1; 0; 0; 0; 0; 0; 0; 0; 1; -1; -1; -1 ]]
        level[5] = [[ int[26] 1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; 1 ]]
        level[6] = [[ int[26] 1; 1; 1; 0; 0; 0; 0; 1; 0; 0; 3; 1; 1; 1; 1; 0; 0; 0; 1; 0; 0; 0; 0; 1; 1; 1 ]]
        level[7] = [[ int[26] 1; 1; 0; 0; 0; 0; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 0; 0; 0; 0; 1; 1 ]]
        level[8] = [[ int[26] 1; 1; 1; 0; 0; 0; 0; 1; 0; 0; 0; 1; 1; 1; 1; 0; 0; 0; 1; 0; 0; 0; 0; 1; 1; 1 ]]
        level[9] = [[ int[26] 1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; 1 ]]
        level[10] = [[ int[26] -1; -1; -1; 1; 0; 0; 0; 0; 0; 0; 0; 1; -1; -1; 1; 0; 0; 0; 0; 0; 0; 0; 1; -1; -1; -1 ]]
        level[11] = [[ int[26] -1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; -1 ]]
        level[12] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[13] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[14] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        //ITEMS
        items[int2(4, 4)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 4)].passable = true
        items[int2(4, 5)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 5)].passable = true
        items[int2(4, 6)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 6)].passable = true
        items[int2(4, 7)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 7)].passable = true
        items[int2(4, 8)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 8)].passable = true
        items[int2(4, 9)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 9)].passable = true
        items[int2(4, 10)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 10)].passable = true
        items[int2(4, 15)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 15)].passable = true
        items[int2(4, 16)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 16)].passable = true
        items[int2(4, 17)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 17)].passable = true
        items[int2(4, 18)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 18)].passable = true
        items[int2(4, 19)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 19)].passable = true
        items[int2(4, 20)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 20)].passable = true
        items[int2(4, 21)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 21)].passable = true
        //
        items[int2(8, 6)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(8, 6)].passable = true
        items[int2(9, 7)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(9, 7)].passable = true
        items[int2(9, 18)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(9, 18)].passable = true
        items[int2(8, 19)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(8, 19)].passable = true
        //
        items[int2(7, 3)].story_id = StoryID PRESSURE1
        items[int2(7, 3)].passable = true
        //
        items[int2(7, 15)].story_id = StoryID DECKA4
        items[int2(7, 15)].passable = true
        items[int2(7, 15)].event = "da3"
        //
        items[int2(10, 8)].img = tiles[int(TileID BLOCK)]
        items[int2(10, 8)].tid = ItemID BLOCK
        items[int2(10, 8)].ittable = true
        //
        items[int2(7, 12)].img = tiles[int(TileID DOORLOCK)]
        items[int2(7, 13)].img = tiles[int(TileID DOORLOCK)]
        items[int2(6, 22)].img = tiles[int(TileID DOORLOCK)]
        items[int2(7, 22)].img = tiles[int(TileID DOORLOCK)]
        items[int2(8, 22)].img = tiles[int(TileID DOORLOCK)]
        //
        items[int2(7, 23)].img = tiles[int(TileID DA4)]
        items[int2(7, 23)].event = "level"
        //
        items[int2(10, 4)].img = tiles[int(TileID CORPSE)]
        items[int2(10, 4)].loot_id = LootID CANDY
        items[int2(10, 5)].img = tiles[int(TileID CORPSE)]
        items[int2(10, 5)].loot_id = LootID PEANUTS
        items[int2(6, 6)].img = tiles[int(TileID LOOTBOX)]
        items[int2(6, 6)].loot_id = LootID BATTERY_X2
        items[int2(5, 15)].img = tiles[int(TileID LOOTBOX)]
        items[int2(5, 15)].loot_id = LootID BATTERY
        items[int2(6, 19)].img = tiles[int(TileID CORPSE)]
        items[int2(6, 19)].loot_id = LootID WATER_X2
        items[int2(10, 21)].img = tiles[int(TileID LOOTBOX)]
        items[int2(10, 21)].loot_id = LootID EMPTY
        //FLOWIE
        items[int2(HPOS, HPOS)].img = tiles[int(TileID FLOWIE)]
        items[int2(HPOS, HPOS)].tid = ItemID FLOWIE
        items[int2(HPOS, HPOS)].ittable = true
        //HERO
        hero.dir = DirID RIGHT
        if hero.hp == 0
            hero.hp = 5
        if hero.energy == 0
            hero.energy = 5
        hero.itty = true
        hero.kate = false
        hero.flowie = true
        hero.carry = true
        hero.pos = int2(2, 7)
        game.story_id = StoryID DECKA3
    elif game.level == 4
        //LEVEL
        game.level_txt = "Deck A4"
        level[0] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[1] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[2] = [[ int[26] -1; -1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 0; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; -1 ]]
        level[3] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 0; 0; 0; 0; 1; 0; 0; 0; 1; 0; 0; 0; 0; 0; 1; 1; 1; -1; -1 ]]
        level[4] = [[ int[26] -1; -1; -1; 1; 1; 0; 2; 0; 0; 0; 2; 0; 0; 0; 0; 0; 2; 0; 0; 0; 0; 0; 1; 1; -1; -1 ]]
        level[5] = [[ int[26] 1; 1; 1; 1; 0; 2; 0; 0; 0; 0; 0; 0; 0; 2; 0; 0; 0; 0; 0; 0; 2; 0; 1; 1; 1; 1 ]]
        level[6] = [[ int[26] 1; 1; 1; 0; 0; 0; 0; 2; 0; 0; 2; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1 ]]
        level[7] = [[ int[26] 1; 1; 0; 0; 0; 2; 0; 0; 0; 0; 0; 0; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1 ]]
        level[8] = [[ int[26] 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1 ]]
        level[9] = [[ int[26] 1; 1; 1; 1; 2; 0; 0; 0; 0; 2; 0; 0; 0; 0; 2; 0; 0; 0; 2; 0; 0; 0; 1; 1; 1; 1 ]]
        level[10] = [[ int[26] -1; -1; -1; 1; 1; 0; 0; 2; 0; 0; 0; 0; 2; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; -1; -1 ]]
        level[11] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 2; 0; 0; 0; 1; 0; 0; 0; 1; 0; 0; 0; 0; 0; 1; 1; 1; -1; -1 ]]
        level[12] = [[ int[26] -1; -1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 0; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; -1 ]]
        level[13] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[14] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        //ITEMS
        items[int2(2, 6)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 7)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 8)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 9)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 10)].img = tiles[int(TileID WALL_UP)]
        //items[int2(2, 16)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 17)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 18)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 19)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 20)].img = tiles[int(TileID WALL_UP)]
        //
        items[int2(3, 6)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 6)].passable = true
        items[int2(3, 7)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 7)].passable = true
        items[int2(3, 8)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 8)].passable = true
        items[int2(3, 9)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 9)].passable = true
        items[int2(3, 10)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 10)].passable = true
        items[int2(4, 11)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 11)].passable = true
        items[int2(4, 15)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 15)].passable = true
        items[int2(3, 16)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 16)].passable = true
        items[int2(3, 17)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 17)].passable = true
        items[int2(3, 18)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 18)].passable = true
        items[int2(3, 19)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 19)].passable = true
        items[int2(3, 20)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 20)].passable = true
        items[int2(8, 12)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(8, 12)].passable = true
        items[int2(8, 13)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(8, 13)].passable = true
        items[int2(8, 14)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(8, 14)].passable = true
        //
        items[int2(6, 3)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(6, 3)].passable = true
        items[int2(5, 4)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 4)].passable = true
        items[int2(4, 5)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 5)].passable = true
        items[int2(4, 21)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 21)].passable = true
        //
        items[int2(3, 12)].img = tiles[int(TileID DOORLOCK2)]
        items[int2(3, 13)].img = tiles[int(TileID DOORLOCK2)]
        items[int2(3, 14)].img = tiles[int(TileID DOORLOCK2)]
        items[int2(6, 22)].img = tiles[int(TileID DOORLOCK)]
        items[int2(7, 22)].img = tiles[int(TileID DOORLOCK)]
        items[int2(8, 22)].img = tiles[int(TileID DOORLOCK)]
        items[int2(11, 12)].img = tiles[int(TileID DOORLOCK2)]
        items[int2(11, 13)].img = tiles[int(TileID DOORLOCK2)]
        items[int2(11, 14)].img = tiles[int(TileID DOORLOCK2)]
        //
        items[int2(2, 16)].img = tiles[int(TileID CP)]
        items[int2(2, 16)].puzzle_id = PuzzleID P1
        //
        items[int2(2, 13)].img = tiles[int(TileID DA4L)]
        items[int2(2, 13)].event = "level"
        items[int2(7, 23)].img = tiles[int(TileID DA5)]
        items[int2(12, 13)].img = tiles[int(TileID DA4R)]
        //
        items[int2(5, 8)].img = tiles[int(TileID CORPSE)]
        items[int2(5, 8)].loot_id = LootID TOMATO
        items[int2(9, 6)].img = tiles[int(TileID CORPSE)]
        items[int2(9, 6)].loot_id = LootID BREAD
        items[int2(8, 10)].img = tiles[int(TileID CORPSE)]
        items[int2(8, 10)].loot_id = LootID BATTERY_X2
        items[int2(6, 18)].img = tiles[int(TileID CORPSE)]
        items[int2(6, 18)].loot_id = LootID MEDICINE
        items[int2(8, 20)].img = tiles[int(TileID CORPSE)]
        items[int2(8, 20)].loot_id = LootID BAR
        items[int2(11, 17)].img = tiles[int(TileID CORPSE)]
        items[int2(11, 17)].loot_id = LootID JUICE
        //
        //
        items[int2(7, 3)].story_id = StoryID MINEFIELD
        items[int2(7, 3)].passable = true
        //
        items[int2(4, 11)].story_id = StoryID CP1
        items[int2(4, 11)].passable = true
        items[int2(5, 11)].story_id = StoryID CP1
        items[int2(5, 11)].passable = true
        items[int2(6, 11)].story_id = StoryID CP1
        items[int2(6, 11)].passable = true
        items[int2(8, 11)].story_id = StoryID CP1
        items[int2(8, 11)].passable = true
        items[int2(9, 11)].story_id = StoryID CP1
        items[int2(9, 11)].passable = true
        items[int2(10, 11)].story_id = StoryID CP1
        items[int2(10, 11)].passable = true
        //FLOWIE
        items[int2(HPOS, HPOS)].img = tiles[int(TileID FLOWIE)]
        items[int2(HPOS, HPOS)].tid = ItemID FLOWIE
        items[int2(HPOS, HPOS)].ittable = true
        //HERO
        hero.dir = DirID RIGHT
        if hero.hp == 0
            hero.hp = 5
        if hero.energy == 0
            hero.energy = 5
        hero.itty = true
        hero.kate = false
        hero.flowie = true
        hero.carry = true
        hero.pos = int2(2, 7)
        game.story_id = StoryID DECKA4
    elif game.level == 5
        //LEVEL
        game.level_txt = "Deck A4L"
        level[0] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[1] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[2] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[3] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[4] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1 ]]
        level[5] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 0; 0; 0; 0; 2; 0; 0; 0; 2; 0; 0; 1; 1; 1; 1 ]]
        level[6] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 0; 0; 2; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1 ]]
        level[7] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 0; 0; 0; 0; 0; 0; 0; 2; 0; 0; 0; 0; 0; 1; 1 ]]
        level[8] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 2; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 2; 1; 1; 1 ]]
        level[9] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 0; 0; 0; 0; 2; 0; 0; 2; 0; 0; 0; 1; 1; 1; 1 ]]
        level[10] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 0; 0; 2; 0; 0; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1 ]]
        level[11] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 0; 0; 0; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[12] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 0; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[13] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[14] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        //ITEMS
        //items[int2(2, 16)].img = tiles[int(TileID WALL_UP)]
        //
        items[int2(5, 11)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 11)].passable = true
        items[int2(5, 12)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 12)].passable = true
        items[int2(5, 13)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 13)].passable = true
        items[int2(5, 14)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 14)].passable = true
        items[int2(5, 15)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 15)].passable = true
        items[int2(5, 16)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 16)].passable = true
        items[int2(5, 17)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 17)].passable = true
        items[int2(5, 18)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 18)].passable = true
        items[int2(5, 19)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 19)].passable = true
        items[int2(5, 20)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 20)].passable = true
        items[int2(5, 21)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 21)].passable = true
        items[int2(6, 22)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(6, 22)].passable = true
        //
        items[int2(7, 23)].img = tiles[int(TileID DA5L)]
        items[int2(7, 23)].event = "level"
        //
        items[int2(6, 18)].img = tiles[int(TileID CORPSE)]
        items[int2(6, 18)].loot_id = LootID PEANUTS
        items[int2(7, 12)].img = tiles[int(TileID CORPSE)]
        items[int2(7, 12)].loot_id = LootID BATTERY_X2
        items[int2(8, 20)].img = tiles[int(TileID CORPSE)]
        items[int2(8, 20)].loot_id = LootID SODA
        items[int2(10, 15)].img = tiles[int(TileID LOOTBOX)]
        items[int2(10, 15)].loot_id = LootID BAR_X2
        //
        items[int2(11, 13)].story_id = StoryID DECKA5L
        items[int2(11, 13)].passable = true
        //FLOWIE
        items[int2(HPOS, HPOS)].img = tiles[int(TileID FLOWIE)]
        items[int2(HPOS, HPOS)].tid = ItemID FLOWIE
        items[int2(HPOS, HPOS)].ittable = true
        //HERO
        hero.dir = DirID UP
        if hero.hp == 0
            hero.hp = 5
        if hero.energy == 0
            hero.energy = 5
        hero.itty = true
        hero.kate = false
        hero.flowie = true
        hero.carry = true
        hero.pos = int2(13, 12)
        game.story_id = StoryID DECKA4L
    elif game.level == 6
        //LEVEL
        game.level_txt = "Deck A5L"
        level[0] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[1] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[2] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[3] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[4] = [[ int[26] -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1 ]]
        level[5] = [[ int[26] 1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 1; 0; 0; 0; 1; 0; 0; 0; 1; 0; 0; 0; 1; 1; 1; 1 ]]
        level[6] = [[ int[26] 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 3; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1 ]]
        level[7] = [[ int[26] 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1 ]]
        level[8] = [[ int[26] 1; 1; 1; 0; 0; 0; 0; 0; 0; 3; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1 ]]
        level[9] = [[ int[26] 1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 1; 0; 0; 0; 1; 0; 0; 3; 1; 0; 0; 0; 1; 1; 1; 1 ]]
        level[10] = [[ int[26] -1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1 ]]
        level[11] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[12] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[13] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[14] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        //ITEMS
        items[int2(5, 4)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 4)].passable = true
        items[int2(5, 5)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 5)].passable = true
        items[int2(5, 6)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 6)].passable = true
        items[int2(5, 7)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 7)].passable = true
        items[int2(5, 8)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 8)].passable = true
        items[int2(5, 9)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 9)].passable = true
        items[int2(5, 11)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 11)].passable = true
        items[int2(5, 12)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 12)].passable = true
        items[int2(5, 13)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 13)].passable = true
        items[int2(5, 15)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 15)].passable = true
        items[int2(5, 16)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 16)].passable = true
        items[int2(5, 17)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 17)].passable = true
        items[int2(5, 19)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 19)].passable = true
        items[int2(5, 20)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 20)].passable = true
        items[int2(5, 21)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 21)].passable = true
        //
        items[int2(6, 10)].img = tiles[int(TileID DOORLOCK)]
        items[int2(7, 10)].img = tiles[int(TileID DOORLOCK)]
        items[int2(8, 10)].img = tiles[int(TileID DOORLOCK)]
        items[int2(6, 14)].img = tiles[int(TileID DOORLOCK)]
        items[int2(7, 14)].img = tiles[int(TileID DOORLOCK)]
        items[int2(8, 14)].img = tiles[int(TileID DOORLOCK)]
        items[int2(6, 18)].img = tiles[int(TileID DOORLOCK)]
        items[int2(7, 18)].img = tiles[int(TileID DOORLOCK)]
        items[int2(8, 18)].img = tiles[int(TileID DOORLOCK)]
        //
        items[int2(9, 6)].img = tiles[int(TileID BLOCK)]
        items[int2(9, 6)].tid = ItemID BLOCK
        items[int2(9, 6)].ittable = true
        //
        items[int2(7, 23)].img = tiles[int(TileID DA6L)]
        items[int2(7, 23)].event = "level"
        //
        items[int2(6, 3)].img = tiles[int(TileID CORPSE)]
        items[int2(6, 3)].loot_id = LootID BREAD
        items[int2(9, 4)].img = tiles[int(TileID CORPSE)]
        items[int2(9, 4)].loot_id = LootID BATTERY_X2
        items[int2(9, 11)].img = tiles[int(TileID CORPSE)]
        items[int2(9, 11)].loot_id = LootID BATTERY_X2
        items[int2(9, 15)].img = tiles[int(TileID CORPSE)]
        items[int2(9, 15)].loot_id = LootID MEDICINE_X2
        items[int2(9, 20)].img = tiles[int(TileID CORPSE)]
        items[int2(9, 20)].loot_id = LootID TOMATO
        //
        items[int2(7, 3)].story_id = StoryID PRESSURE2
        items[int2(7, 3)].passable = true
        //
        items[int2(6, 19)].story_id = StoryID DECKA6L
        items[int2(6, 19)].passable = true
        items[int2(7, 19)].story_id = StoryID DECKA6L
        items[int2(7, 19)].passable = true
        items[int2(7, 19)].story_id = StoryID DECKA6L
        items[int2(7, 19)].passable = true
        //FLOWIE
        items[int2(HPOS, HPOS)].img = tiles[int(TileID FLOWIE)]
        items[int2(HPOS, HPOS)].tid = ItemID FLOWIE
        items[int2(HPOS, HPOS)].ittable = true
        //HERO
        hero.dir = DirID RIGHT
        if hero.hp == 0
            hero.hp = 5
        if hero.energy == 0
            hero.energy = 5
        hero.itty = true
        hero.kate = false
        hero.flowie = true
        hero.carry = true
        hero.pos = int2(2, 7)
        game.story_id = StoryID DECKA5L
    elif game.level == 7
        //LEVEL
        game.level_txt = "Deck A6L"
        level[0] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[1] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[2] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[3] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[4] = [[ int[26] -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[5] = [[ int[26] 1; 1; 1; 1; 0; 0; 0; 0; 2; 2; 0; 0; 0; 0; 2; 0; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[6] = [[ int[26] 1; 1; 1; 0; 2; 0; 0; 0; 0; 0; 0; 0; 0; 2; 2; 0; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[7] = [[ int[26] 1; 1; 0; 0; 0; 0; 0; 2; 0; 0; 0; 0; 0; 0; 0; 0; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[8] = [[ int[26] 1; 1; 1; 0; 2; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 2; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[9] = [[ int[26] 1; 1; 1; 1; 0; 0; 0; 0; 0; 2; 2; 0; 0; 0; 0; 0; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[10] = [[ int[26] -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 0; 0; 0; 0; 0; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[11] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 0; 0; 0; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[12] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 0; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[13] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[14] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        //ITEMS
        //items[int2(2, 16)].img = tiles[int(TileID WALL_UP)]
        //
        items[int2(5, 4)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 4)].passable = true
        items[int2(5, 5)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 5)].passable = true
        items[int2(5, 6)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 6)].passable = true
        items[int2(5, 7)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 7)].passable = true
        items[int2(5, 8)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 8)].passable = true
        items[int2(5, 9)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 9)].passable = true
        items[int2(5, 10)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 10)].passable = true
        items[int2(5, 11)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 11)].passable = true
        items[int2(5, 12)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 12)].passable = true
        items[int2(5, 13)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 13)].passable = true
        items[int2(5, 14)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 14)].passable = true
        items[int2(5, 15)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 15)].passable = true
        items[int2(6, 3)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(6, 3)].passable = true
        //
        items[int2(12, 13)].img = tiles[int(TileID DA6)]
        items[int2(12, 13)].event = "level"
        //
        items[int2(9, 6)].img = tiles[int(TileID CORPSE)]
        items[int2(9, 6)].loot_id = LootID EMPTY
        items[int2(8, 10)].img = tiles[int(TileID CORPSE)]
        items[int2(8, 10)].loot_id = LootID BATTERY
        items[int2(6, 15)].img = tiles[int(TileID CORPSE)]
        items[int2(6, 15)].loot_id = LootID BAR
        items[int2(10, 11)].img = tiles[int(TileID LOOTBOX)]
        items[int2(10, 11)].loot_id = LootID JUICE
        items[int2(10, 15)].img = tiles[int(TileID LOOTBOX)]
        items[int2(10, 15)].loot_id = LootID CANDY
        //
        items[int2(7, 3)].story_id = StoryID DECKA6
        items[int2(7, 3)].passable = true
        //FLOWIE
        items[int2(HPOS, HPOS)].img = tiles[int(TileID FLOWIE)]
        items[int2(HPOS, HPOS)].tid = ItemID FLOWIE
        items[int2(HPOS, HPOS)].ittable = true
        //HERO
        hero.dir = DirID RIGHT
        if hero.hp == 0
            hero.hp = 5
        if hero.energy == 0
            hero.energy = 5
        hero.itty = true
        hero.kate = false
        hero.flowie = true
        hero.carry = true
        hero.pos = int2(2, 7)
        game.story_id = StoryID DECKA6L
    elif game.level == 8
        //LEVEL
        game.level_txt = "Deck A6"
        level[0] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[1] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; 1; 1; 1; 1; 1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[2] = [[ int[26] -1; -1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 0; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; -1 ]]
        level[3] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 0; 0; 0; 0; 1; 0; 0; 0; 1; 0; 0; 0; 0; 0; 1; 1; 1; -1; -1 ]]
        level[4] = [[ int[26] -1; -1; -1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; -1; -1 ]]
        level[5] = [[ int[26] 1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; -1; -1 ]]
        level[6] = [[ int[26] 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; -1; -1 ]]
        level[7] = [[ int[26] 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; -1; -1 ]]
        level[8] = [[ int[26] 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; -1; -1 ]]
        level[9] = [[ int[26] 1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; -1; -1 ]]
        level[10] = [[ int[26] -1; -1; -1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; -1; -1 ]]
        level[11] = [[ int[26] -1; -1; -1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; -1; -1 ]]
        level[12] = [[ int[26] -1; -1; -1; -1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; -1; -1; -1 ]]
        level[13] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        level[14] = [[ int[26] -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1; -1 ]]
        //ITEMS
        items[int2(2, 6)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 7)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 8)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 9)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 10)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 16)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 17)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 18)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 19)].img = tiles[int(TileID WALL_UP)]
        items[int2(2, 20)].img = tiles[int(TileID WALL_UP)]
        //
        items[int2(3, 6)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 6)].passable = true
        items[int2(3, 7)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 7)].passable = true
        items[int2(3, 8)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 8)].passable = true
        items[int2(3, 9)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 9)].passable = true
        items[int2(3, 10)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 10)].passable = true
        items[int2(4, 11)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 11)].passable = true
        items[int2(4, 15)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 15)].passable = true
        items[int2(3, 16)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 16)].passable = true
        items[int2(3, 17)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 17)].passable = true
        items[int2(3, 18)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 18)].passable = true
        items[int2(3, 19)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 19)].passable = true
        items[int2(3, 20)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(3, 20)].passable = true
        items[int2(6, 22)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(6, 22)].passable = true
        //
        items[int2(6, 3)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(6, 3)].passable = true
        items[int2(5, 4)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(5, 4)].passable = true
        items[int2(4, 5)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 5)].passable = true
        items[int2(4, 21)].img = tiles[int(TileID WALL_FLOOR)]
        items[int2(4, 21)].passable = true
        //
        items[int2(6, 3)].img = tiles[int(TileID DOORLOCK)]
        items[int2(7, 3)].img = tiles[int(TileID DOORLOCK)]
        items[int2(8, 3)].img = tiles[int(TileID DOORLOCK)]
        //
        items[int2(7, 2)].img = tiles[int(TileID DA5)]
        //
        items[int2(4, 10)].img = tiles[int(TileID LOOTBOX)]
        items[int2(4, 10)].loot_id = LootID CHOCOLATE
        items[int2(4, 16)].img = tiles[int(TileID LOOTBOX)]
        items[int2(4, 16)].loot_id = LootID WATER
        items[int2(8, 9)].img = tiles[int(TileID CORPSE)]
        items[int2(8, 9)].loot_id = LootID BATTERY
        items[int2(10, 11)].img = tiles[int(TileID CORPSE)]
        items[int2(10, 11)].loot_id = LootID CUPCAKE
        //
        items[int2(7, 13)].img = tiles[int(TileID PC)]
        items[int2(7, 13)].event = "da6pc"
        //
        items[int2(3, 12)].story_id = StoryID END
        items[int2(3, 12)].passable = true
        items[int2(3, 13)].story_id = StoryID END
        items[int2(3, 13)].passable = true
        items[int2(3, 14)].story_id = StoryID END
        items[int2(3, 14)].passable = true
        //FLOWIE
        items[int2(HPOS, HPOS)].img = tiles[int(TileID FLOWIE)]
        items[int2(HPOS, HPOS)].tid = ItemID FLOWIE
        items[int2(HPOS, HPOS)].ittable = true
        //HERO
        hero.dir = DirID DOWN
        if hero.hp == 0
            hero.hp = 5
        if hero.energy == 0
            hero.energy = 5
        hero.itty = true
        hero.kate = false
        hero.flowie = true
        hero.carry = true
        hero.pos = int2(13, 2)
        game.story_id = StoryID DECKA6
   
def draw_items()
	var x = 0
    var y = 0
    var item_pos = int2(0, 0)
  	enable_alpha_blend()
    for h in range(0, CELL_HEIGHT)
        y = h * CELL_SIZE
        for w in range(0, CELL_WIDTH)
            x = w * CELL_SIZE
            item_pos = int2(h, w)
            if key_exists(items, item_pos)
                if items[item_pos].img.width > 0
                    items[item_pos].img |> draw_image(x + X_OFF, y + Y_OFF)
    disable_alpha_blend()


def draw_level()
    //draw_starfield()
    fill_rect(0, 0, WIDTH, HEIGHT, BACKGROUND_COLOR)
	var x = 0 //* CELL_SIZE
    var y = 0 //* CELL_SIZE
    var i = 0
    //for k in keys(level) //), values(level)
    for h in range(0, CELL_HEIGHT)
        y = h * CELL_SIZE
        for w in range(0, CELL_WIDTH)
            x = w * CELL_SIZE
            i = level[h][w]
            if i != -1
                tiles[i] |> draw_image(x + X_OFF, y + Y_OFF)
                //if i == 2
                //    text_out(x + X_OFF, y + Y_OFF, "{i}\n{h},{w}", 0x00FFFF)
    draw_items()

// INPUT //
def update_input()
    if game.state == StateID MENU
        if get_key_down(VK_ESCAPE)
            schedule_quit_game()
        elif get_key_down(VK_RETURN)
            load_game()
            play_sfx(SfxID GAME)
            game.state = StateID GAME
    elif game.state == StateID GAME
        if get_key_down(VK_ESCAPE)
            game.state = StateID MENU
            play_sfx(SfxID MENU)
            //schedule_quit_game()
        elif get_key_down(VK_A)
            move_hero_left()
        elif get_key_down(VK_D)
            move_hero_right()
        elif get_key_down(VK_W)
            move_hero_up()
        elif get_key_down(VK_S)
            move_hero_down()
        elif get_key_down(VK_RETURN)
            use_itty()
    elif game.state == StateID STORY
        if get_key_down(VK_RETURN)
            ok_story()
    elif game.state == StateID QUEST
        if get_key_down(VK_RETURN)
            ok_quest()
    elif game.state == StateID LOOT
        if get_key_down(VK_RETURN)
            ok_loot()
    elif game.state == StateID PUZZLE
        if get_key(VK_ESCAPE)
            game.state = StateID GAME
        //elif get_key_down(VK_A)
        //    move_puzzle_left()
        //elif get_key_down(VK_D)
        //    move_puzzle_right()
        //elif get_key_down(VK_W)
        //    move_puzzle_up()
        //elif get_key_down(VK_S)
        //    move_puzzle_down()
        //elif get_key_down(VK_E)
        //    rotate_puzzle()
        if get_key_down(VK_1)
            rotate_puzzle(1)
        elif get_key_down(VK_2)
            rotate_puzzle(2)
        elif get_key_down(VK_3)
            rotate_puzzle(3)
        elif get_key_down(VK_4)
            rotate_puzzle(4)
        elif get_key_down(VK_5)
            rotate_puzzle(5)
        elif get_key_down(VK_6)
            rotate_puzzle(6)
        elif get_key_down(VK_7)
            rotate_puzzle(7)
        elif get_key_down(VK_8)
            rotate_puzzle(8)
        elif get_key_down(VK_9)
            rotate_puzzle(9)
        elif get_key_down(VK_RETURN)
            ok_puzzle()
    elif game.state == StateID GAMEWIN
        if get_key_up(VK_RETURN)
            play_sfx(SfxID MENU)
            game.state = StateID MENU
    elif game.state == StateID GAMEFAIL
        if get_key_up(VK_RETURN)
            play_sfx(SfxID MENU)
            game.state = StateID MENU



// MAIN //

def load_game()
	load_level()

def new_game()
    game.state = StateID MENU
	game.level = 1
    init_sfx()
    init_gui()
	init_levels()
	init_hero()
    game.sfx = sfx[int(SfxID MENU)] |> play_sound_loop()
    //load_game()

// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize
    set_window_title(GAME_TITLE)
    set_resolution(WIDTH, HEIGHT)
	set_antialiasing(4)
    randomize_seed(game.seed)
	new_game()

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(dt: float)
    update_input()
    if get_key(VK_F)
        schedule_screenshot("screenshot{random_int(game.seed)}.png")

// this function will be called every frame after 'act',
// you can draw anything in this function
[export]
def draw
    if game.state == StateID MENU
        draw_menu()
    else //StateID GAME
        draw_level()
        draw_hero()
        draw_gui()
        if game.state == StateID STORY
            draw_story()
        elif game.state == StateID QUEST
            draw_quest()
        elif game.state == StateID LOOT
            draw_loot()
        elif game.state == StateID PUZZLE
            draw_puzzle()
        elif game.state == StateID GAMEWIN
            draw_win()
        elif game.state == StateID GAMEFAIL
            draw_fail()
