#===============================================================================
# Rewrites parts of the Summary Screen UI to match FRLG.
#===============================================================================
class MoveSelectionSprite < Sprite
  def refresh
    w = @movesel.width
    h = @movesel.height / 2
    self.x = 258
    self.y = 40 + (self.index * 64)
    self.y += 10 if @fifthmove && self.index == Pokemon::MAX_MOVES   # Add a gap
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0, h, w, h)
    else
      self.src_rect.set(0, 0, w, h)
    end
  end
end

#===============================================================================
#
#===============================================================================
class PokemonSummary_Scene
  MARK_WIDTH  = 16
  MARK_HEIGHT = 16

  # Text Colors
  LABEL_BASE = Color.new(248, 248, 248)
  LABEL_SHADOW = Color.new(120, 128, 144)
  PURPLE_TEXT_BASE = Color.new(160, 64, 160)
  BLACK_TEXT_BASE = Color.new(64, 64, 64)

  # Modular UI Screen Seings
  MAX_PAGE_ICONS = 5
  PAGE_ICONS_POSITION = [202, 0]
  PAGE_ICON_SIZE = [38, 32]

  # Draws the page icons (from Modular UI Scenes), changed for [FRLG] Summary Screen
  def drawPageIcons(moveDetailPg = false)
    setPages if !@page_list || @page_list.empty?
    iconPos    = 0
    imagepos   = []
    xpos, ypos = PAGE_ICONS_POSITION
    w, h       = PAGE_ICON_SIZE
    size       = MAX_PAGE_ICONS 
    range      = [@page_list.length, MAX_PAGE_ICONS]
    page       = @page_list.find_index(@page_id)
    endPage    = [size - 1, @page_list.length - (page / size).floor * size - 1].min
    pageZ      = page  % size
    for i in 0..endPage
      path = "Graphics/UI/Summary/" + (!moveDetailPg ? "page_icons" : "page_icons_moves")
      iconRectX = (pageZ == i) ? w : (pageZ > i) ? 0 : 2 * w
      suffix = UIHandlers.get_info(:summary, @page_list[i], :suffix)
      imagepos.push([path, xpos + (iconPos * (w - 6)), ypos, iconRectX, 0, w, h])
      iconPos += 1
    end
    if PAGE_ICONS_SHOW_ARROWS
      path = "Graphics/UI/Summary/page_arrows"
      if (page / size).floor > 0
        imagepos.push([path, xpos - 4, ypos + 6, 0, 0, 12, 20])
      end
      if (endPage == size - 1) && (@page_list.length - ((page / size).floor + 1) * size > 0)
        imagepos.push([path, xpos + (iconPos * (w - 8)) + 16, ypos + 6, 14, 0, 12, 20])
      end
    end
    pbDrawImagePositions(@sprites["overlay"].bitmap, imagepos)
  end  

  def pbStartScene(party, partyindex, inbattle = false)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @inbattle   = inbattle
    @page = 1		  
    @typebitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    @markingbitmap = AnimatedBitmap.new("Graphics/UI/Summary/markings")			
    @markingbitmap_2 = AnimatedBitmap.new("Graphics/UI/Summary/markings_2")	
    @teraPlugin    = false
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["overlay_shiny"] = IconSprite.new(4, 36, @viewport)
    @sprites["overlay_shiny"].setBitmap("Graphics/UI/Summary/overlay_shiny")
    @sprites["overlay_shiny"].src_rect.height = @sprites["overlay_shiny"].bitmap.height / 2
    @sprites["pokemon"] = PokemonSprite.new(@viewport)
    @sprites["pokemon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokemon"].x = 106
    @sprites["pokemon"].y = 160
    @sprites["pokemon"].mirror = true
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokeicon"].x       = 38
    @sprites["pokeicon"].y       = 78
    @sprites["pokeicon"].mirror = true
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"] = ItemIconSprite.new(484 , 228, @pokemon.item_id, @viewport)
    @sprites["itemicon"].blankzero = true
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["overlay_cmdinfo"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay_cmdinfo"].bitmap)
    @sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movepresel"].visible     = false
    @sprites["movepresel"].preselected = true
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movesel"].visible = false
    @sprites["markingbg"] = Window_AdvancedTextPokemon.newWithSize("", Graphics.width - 216, Graphics.height - 190, 216, 190, @viewport)
    @sprites["markingbg"].visible = false
    @sprites["markingbg"].setSkin(MessageConfig.pbGetSystemFrame)
    @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["markingoverlay"].visible = false
    @sprites["markingoverlay"].z = @viewport.z + 1
    pbSetSystemFont(@sprites["markingoverlay"].bitmap)
    @sprites["markingsel"] = IconSprite.new(0, 0, @viewport)
    @sprites["markingsel"].setBitmap("Graphics/UI/sel_arrow")
    @sprites["markingsel"].visible = false
    @sprites["markingsel"].z = @viewport.z + 1					 
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
    pbBottomLeftLines(@sprites["messagebox"], 2)
    @nationalDexList = [:NONE]
    GameData::Species.each_species { |s| @nationalDexList.push(s.species) }
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @markingbitmap&.dispose
    @markingbitmap_2&.dispose
    @viewport.dispose
  end

  def pbStartForgetScene(party, partyindex, move_to_learn)
    @page_id = :page_moves
    @page_list = [:page_moves]
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @page = 3
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["overlay_shiny"] = IconSprite.new(4, 36, @viewport)
    @sprites["overlay_shiny"].setBitmap("Graphics/UI/Summary/overlay_shiny")
    @sprites["overlay_shiny"].src_rect.height = @sprites["overlay_shiny"].bitmap.height / 2
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["overlay_cmdinfo"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay_cmdinfo"].bitmap)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokeicon"].x       = 38
    @sprites["pokeicon"].y       = 78
    @sprites["pokeicon"].mirror = true
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport, !move_to_learn.nil?)
    @sprites["movesel"].visible = false
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
    drawSelectedMove(new_move, @pokemon.moves[0])
    pbFadeInAndShow(@sprites)
  end

  def drawShinyOverlay(bitmap, type, visible)
    @sprites["overlay_shiny"].src_rect.y = (type == 1) ? 0 : @sprites["overlay_shiny"].bitmap.height / type
    if visible
      @sprites["overlay_shiny"].visible = true
    else
      @sprites["overlay_shiny"].visible = false
    end
  end

  def writePageCommandInfo(overlay, page_info, x, y, base, shadow)
    overlay.clear
    pbDrawTextPositions(overlay, [[_INTL("{1}", page_info), x, y, :left, base, shadow]])
  end

  def drawPage(page)
    setPages # Gets the list of pages and current page ID.
    suffix = UIHandlers.get_info(:summary, @page_id, :suffix)
    # Set background image
    @sprites["background"].setBitmap("Graphics/UI/Summary/bg_#{suffix}")
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokeicon"].pokemon = @pokemon
    if PluginManager.installed?("[DBK] Terastallization")
      @teraPlugin = Settings::SUMMARY_TERA_TYPES && @pokemon.tera_type	
    end
    @sprites["itemicon"].item = @pokemon.item_id
    @sprites["itemicon"].visible = @page_id == :page_info || @page_id == :page_egg
    @sprites["itemicon"].y = @page_id == :page_egg ? 260 : (228 + (@teraPlugin ? 32 : 0)) 
    overlay = @sprites["overlay"].bitmap
    overlay_cmdinfo = @sprites["overlay_cmdinfo"].bitmap
    overlay.clear
    overlay_cmdinfo.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(96, 96, 96)
    drawPageIcons # Draws the page icons.
    imagepos = []
    # Draws general page info.
    # Show the Poké Ball containing the Pokémon
    ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
    imagepos.push([ballimage, 211, 238])
    # Write various bits of text
    pagename = UIHandlers.get_info(:summary, @page_id, :name)
    textpos = [
      [pagename, 8, 6, :left, base, shadow],
      [@pokemon.name, 74, 40, :left, base, shadow],
    ]
    # Gives information about what pressing the use button will do for the given page
    writePageCommandInfo(overlay_cmdinfo, "Options", 428, 6, 
                          Color.new(248, 248, 248), Color.new(96, 96, 96))
    # Draws additional info for non-Egg Pokémon.
    if !@pokemon.egg?
      # Show status/fainted/Pokérus infected icon
      status = -1
      if @pokemon.fainted?
        status = GameData::Status.count - 1
      elsif @pokemon.status != :NONE
        status = GameData::Status.get(@pokemon.status).icon_position
      elsif @pokemon.pokerusStage == 1
        status = GameData::Status.count
      end
      if status >= 0
        imagepos.push(["Graphics/UI/statuses", 202, 68, 0, 16 * status, 44, 16])
      end
      # Show Pokérus cured icon
      if @pokemon.pokerusStage == 2
        imagepos.push(["Graphics/UI/Summary/icon_pokerus", 106, 254])
      end
      # Draws an additional overlay for the sprite placeholder if the Pokémon is shiny
      drawShinyOverlay(overlay, 1, @pokemon.shiny?)
      # Show shininess star
      imagepos.push(["Graphics/UI/shiny", 214, 42]) if @pokemon.shiny?
      # Writes the Pokémon's level
      textpos.push([_INTL("Lv{1}", @pokemon.level.to_s), 8, 40, :left, base, shadow])
      # Write the gender symbol
      if @pokemon.male?
        textpos.push([_INTL("♂"), 246, 40, :right, Color.new(160, 192, 240), Color.new(48, 80, 200)])
      elsif @pokemon.female?
        textpos.push([_INTL("♀"), 246, 40, :right, Color.new(255, 189, 115), Color.new(231, 8, 8)])
      end
    end
    # Draws the page.
    pbDrawImagePositions(overlay, imagepos)
    pbDrawTextPositions(overlay, textpos)
    UIHandlers.call(:summary, @page_id, "layout", @pokemon, self)
    # Draw the Pokémon's markings
    drawMarkings(overlay, 10, 254)
  end

  def drawPageOne
    overlay = @sprites["overlay"].bitmap
    @sprites["background"].setBitmap("Graphics/UI/Summary/bg_info_tera") if @teraPlugin
    base   = BLACK_TEXT_BASE
    light_shadow = Color.new(202, 196, 190)
    dark_shadow = Color.new(200, 180, 160)
    # If a Shadow Pokémon, draw the heart gauge area and bar
    if @pokemon.shadowPokemon?
      shadowfract = @pokemon.heart_gauge.to_f / @pokemon.max_gauge_size
      imagepos = [
        ["Graphics/UI/Summary/overlay_shadow", 132, 288],
        ["Graphics/UI/Summary/overlay_shadowbar", 338, 362, 0, 0, (shadowfract * 158).floor, -1]
      ]
      pbDrawImagePositions(overlay, imagepos)
    end
    # Write various bits of text
    teraY = @teraPlugin ? 32 : 0
    textpos = [
      [_INTL("Dex No."), 308, 46, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [_INTL("Species"), 308, 78, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [@pokemon.speciesName, 358, 78, :left, base, light_shadow],
      [_INTL("Type"), 308, 110, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [_INTL("OT"), 308, 142 + teraY, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [_INTL("ID No."), 308, 174 + teraY, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [_INTL("Item"), 308, 206 + teraY, :center, LABEL_BASE, LABEL_SHADOW, :outline]
    ]
    textpos.push([_INTL("Experience"), 75, 298, :center, LABEL_BASE, LABEL_SHADOW, :outline]) if !@pokemon.shadowPokemon?
    # Write the Regional/National Dex number
    dexnum = 0
    dexnumshift = false
    if $player.pokedex.unlocked?(-1)   # National Dex is unlocked
      dexnum = @nationalDexList.index(@pokemon.species_data.species) || 0
      dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(-1)
    else
      ($player.pokedex.dexes_count - 1).times do |i|
        next if !$player.pokedex.unlocked?(i)
        num = pbGetRegionalNumber(i, @pokemon.species)
        break if num <= 0
        dexnum = num
        dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(i)
        break
      end
    end
    if dexnum <= 0
      textpos.push(["???", 358, 46, :left, base, light_shadow])
    else
      dexnum -= 1 if dexnumshift
      textpos.push([sprintf("%03d", dexnum), 358, 46, :left, base, light_shadow])
    end
    # Write Original Trainer's name and ID number
    if @pokemon.owner.name.empty?
      textpos.push([_INTL("RENTAL"), 358, 142 + teraY, :left, base, light_shadow])
      textpos.push(["?????", 358, 174 + teraY, :left, base, light_shadow])
    else
      ownerbase   = Color.new(64, 64, 64)
      ownershadow = Color.new(216, 216, 192)
      case @pokemon.owner.gender
      when 0
        ownerbase = Color.new(48, 80, 200)
        ownershadow = Color.new(160, 192, 240)
      when 1
        ownerbase = Color.new(231, 8, 8)
        ownershadow = Color.new(259, 189, 115)
      end
      textpos.push([@pokemon.owner.name, 358, 142 + teraY, :left, ownerbase, ownershadow])
      textpos.push([sprintf("%05d", @pokemon.owner.public_id), 358, 174 + teraY, :left,
                    base, light_shadow])
    end
    # Write the held item's name
    if @pokemon.hasItem?
      textpos.push([@pokemon.item.name, 266, 228 + teraY, :left, base, light_shadow])
    else
      textpos.push([_INTL("None"), 266, 228 + teraY, :left, base, light_shadow])
    end
    # Write Exp text OR heart gauge message (if a Shadow Pokémon)
    if @pokemon.shadowPokemon?
      textpos.push([_INTL("Heart Gauge"), 75, 298, :center, LABEL_BASE, LABEL_SHADOW, :outline])
      black_text_tag = shadowc3tag(BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
      heartmessage = [_INTL("The door to its heart is open! Undo the final lock!"),
                      _INTL("The door to its heart is almost fully open."),
                      _INTL("The door to its heart is nearly open."),
                      _INTL("The door to its heart is opening wider."),
                      _INTL("The door to its heart is opening up."),
                      _INTL("The door to its heart is tightly shut.")][@pokemon.heartStage]
      memo = black_text_tag + heartmessage
      drawFormattedTextEx(overlay, 142, 304, 362, memo)
    else
      endexp = @pokemon.growth_rate.minimum_exp_for_level(@pokemon.level + 1)
      textpos.push([_INTL("Exp. Points"), 142, 302, :left, base, dark_shadow])
      textpos.push([@pokemon.exp.to_s_formatted, 504, 302, :right, base, light_shadow])
      textpos.push([_INTL("To Next Lv."), 142, 334, :left, base, dark_shadow])
      textpos.push([(endexp - @pokemon.exp).to_s_formatted, 504, 334, :right, base, light_shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw Pokémon type(s)
    @pokemon.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(0, type_number * 28, 64, 28)
      type_x = (@pokemon.types.length == 1) ? 358 : 358 + (72 * i)
      overlay.blt(type_x, 106, @typebitmap.bitmap, type_rect)
    end
    # Draw Exp bar
    if @pokemon.level < GameData::GrowthRate.max_level && !@pokemon.shadowPokemon?
      w = @pokemon.exp_fraction * 128
      w = ((w / 2).round) * 2
      pbDrawImagePositions(overlay,
                          [["Graphics/UI/Summary/overlay_exp", 368, 362, 0, 0, w, 6]])
    end
  end

  def drawPageOneEgg
    overlay = @sprites["overlay"].bitmap
    drawShinyOverlay(overlay, 1, false)
    base   = BLACK_TEXT_BASE
    shadow = Color.new(202, 196, 190)
    # Write various bits of text
    textpos = [
      [_INTL("Trainer Memo"), 336, 46, :center, LABEL_BASE, LABEL_SHADOW, :outline], 
      [_INTL("Item"), 336, 238, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [_INTL("State"), 75, 290, :center, LABEL_BASE, LABEL_SHADOW, :outline]
    ]
    # Write the held item's name
    if @pokemon.hasItem?
      textpos.push([@pokemon.item.name, 266, 260, :left, base, shadow])
    else
      textpos.push([_INTL("None"), 266, 260, :left, base, shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Writes the trainer memo
    purple_text_tag = shadowc3tag(PURPLE_TEXT_BASE, Color.new(226, 196, 214))
    black_text_tag = shadowc3tag(BLACK_TEXT_BASE, shadow)
    memo = ""
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      memo += black_text_tag + _INTL("{1} {2}, {3}", date, month, year) + "\n"
    end
    mapname = pbGetMapNameFromId(@pokemon.obtain_map)
    mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
    if mapname && mapname != ""
      mapname = purple_text_tag + mapname + black_text_tag
      memo += black_text_tag + _INTL("A mysterious Pokémon Egg received from {1}.", mapname) + "\n"
    else
      memo += black_text_tag + _INTL("A mysterious Pokémon Egg.") + "\n"
    end
    drawFormattedTextEx(overlay, 266, 78, 238, memo)
    # Writes the egg's state
    eggstate = _INTL("It looks like this Egg will take a long time to hatch.")
    eggstate = _INTL("What will hatch from this? It doesn't seem close to hatching.") if @pokemon.steps_to_hatch < 10_200
    eggstate = _INTL("It appears to move occasionally. It may be close to hatching.") if @pokemon.steps_to_hatch < 2550
    eggstate = _INTL("Sounds can be heard coming from inside! It will hatch soon!") if @pokemon.steps_to_hatch < 1275
    drawTextEx(overlay, 16, 322, 488, 2, eggstate, base, shadow)
  end 

  def drawPageTwo
    overlay = @sprites["overlay"].bitmap
    purple_text_tag = shadowc3tag(PURPLE_TEXT_BASE, Color.new(218, 196, 230))
    black_text_tag = shadowc3tag(BLACK_TEXT_BASE, Color.new(194, 196, 206))
    # Writes the heading
    pbDrawTextPositions(overlay, [[_INTL("Trainer Memo"), 336, 46, :center, 
                                  LABEL_BASE, LABEL_SHADOW, :outline]])
    memo = ""
    # Write nature
    showNature = !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
    if showNature
      nature_name = purple_text_tag + @pokemon.nature.name + black_text_tag
      memo += _INTL("{1} nature.", nature_name) + " "
      best_stat = nil
      best_iv = 0
      stats_order = [:HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE]
      start_point = @pokemon.personalID % stats_order.length   # Tiebreaker
      stats_order.length.times do |i|
        stat = stats_order[(i + start_point) % stats_order.length]
        if !best_stat || @pokemon.iv[stat] > @pokemon.iv[best_stat]
          best_stat = stat
          best_iv = @pokemon.iv[best_stat]
        end
      end
      characteristics = {
        :HP              => [_INTL("Loves to eat."),
                              _INTL("Takes plenty of siestas."),
                              _INTL("Nods off a lot."),
                              _INTL("Scatters things often."),
                              _INTL("Likes to relax.")],
        :ATTACK          => [_INTL("Proud of its power."),
                              _INTL("Likes to thrash about."),
                              _INTL("A little quick tempered."),
                              _INTL("Likes to fight."),
                              _INTL("Quick tempered.")],
        :DEFENSE         => [_INTL("Sturdy body."),
                              _INTL("Capable of taking hits."),
                              _INTL("Highly persistent."),
                              _INTL("Good endurance."),
                              _INTL("Good perseverance.")],
        :SPECIAL_ATTACK  => [_INTL("Highly curious."),
                              _INTL("Mischievous."),
                              _INTL("Thoroughly cunning."),
                              _INTL("Often lost in thought."),
                              _INTL("Very finicky.")],
        :SPECIAL_DEFENSE => [_INTL("Strong willed."),
                              _INTL("Somewhat vain."),
                              _INTL("Strongly defiant."),
                              _INTL("Hates to lose."),
                              _INTL("Somewhat stubborn.")],
        :SPEED           => [_INTL("Likes to run."),
                              _INTL("Alert to sounds."),
                              _INTL("Impetuous and silly."),
                              _INTL("Somewhat of a clown."),
                              _INTL("Quick to flee.")]
      }
      memo += black_text_tag + characteristics[best_stat][best_iv % 5] + "\n"
    end
    memo += "\n" if @pokemon.obtain_method != 1 && showNature
    # Write date received
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      memo += black_text_tag + _INTL("{1} {2}, {3}", date, month, year) + "\n"
    end
    # Write map name Pokémon was received on
    mapname = pbGetMapNameFromId(@pokemon.obtain_map)
    mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
    mapname = _INTL("Faraway place") if nil_or_empty?(mapname)
    memo += purple_text_tag + mapname + "\n"
    # Write how Pokémon was obtained
    mettext = [
      _INTL("Met at Lv. {1}.", @pokemon.obtain_level),
      _INTL("Egg received."),
      _INTL("Traded at Lv. {1}.", @pokemon.obtain_level),
      "",
      _INTL("Had a fateful encounter at Lv. {1}.", @pokemon.obtain_level)
    ][@pokemon.obtain_method]
    memo += black_text_tag + mettext + "\n" if mettext && mettext != ""
    # If Pokémon was hatched, write when and where it hatched
    if @pokemon.obtain_method == 1
      if @pokemon.timeEggHatched
        date  = @pokemon.timeEggHatched.day
        month = pbGetMonthName(@pokemon.timeEggHatched.mon)
        year  = @pokemon.timeEggHatched.year
        memo += black_text_tag + _INTL("{1} {2}, {3}", date, month, year) + "\n"
      end
      mapname = pbGetMapNameFromId(@pokemon.hatched_map)
      mapname = _INTL("Faraway place") if nil_or_empty?(mapname)
      memo += purple_text_tag + mapname + "\n"
      memo += black_text_tag + _INTL("Egg hatched.") + "\n"
    end
    # Write all text
    drawFormattedTextEx(overlay, 266, 78, 238, memo)
  end

  def drawPageThree
    overlay = @sprites["overlay"].bitmap
    base   = BLACK_TEXT_BASE
    light_shadow = Color.new(202, 202, 178)
    dark_shadow = Color.new(200, 200, 136)
    # Determine which stats are boosted and lowered by the Pokémon's nature
    statsbases = {}
    GameData::Stat.each_main { |s| statsbases[s.id] = base }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
      @pokemon.nature_for_stats.stat_changes.each do |change|
        statsbases[change[0]] = Color.new(231, 8, 8) if change[1] > 0
        statsbases[change[0]] = Color.new(48, 80, 200) if change[1] < 0
      end
    end
    # Write various bits of text
    textpos = [
      [_INTL("HP"), 308, 46, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [sprintf("%d/%d", @pokemon.hp, @pokemon.totalhp), 504, 46, :right, statsbases[:HP], light_shadow],
      [_INTL("Attack"), 308, 88, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [@pokemon.attack.to_s, 504, 88, :right, statsbases[:ATTACK], light_shadow],
      [_INTL("Defense"), 308, 120, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [@pokemon.defense.to_s, 504, 120, :right, statsbases[:DEFENSE], light_shadow],
      [_INTL("Sp. Atk"), 308, 152, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [@pokemon.spatk.to_s, 504, 152, :right, statsbases[:SPECIAL_ATTACK], light_shadow],
      [_INTL("Sp. Def"), 308, 184, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [@pokemon.spdef.to_s, 504, 184, :right, statsbases[:SPECIAL_DEFENSE], light_shadow],
      [_INTL("Speed"), 308, 216, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [@pokemon.speed.to_s, 504, 216, :right, statsbases[:SPEED], light_shadow],
      [_INTL("Ability"), 75, 292, :center, LABEL_BASE, LABEL_SHADOW, :outline]
    ]
    # Draw ability name and description
    ability = @pokemon.ability
    # The next part of the script makes it so that hidden ability names use a 
    # different color. If you do not want it, just replace the next line with:
    # hidden_ability = false
    hidden_ability = @pokemon.hasHiddenAbility?
    ability_base =  hidden_ability ? PURPLE_TEXT_BASE : base
    ability_shadow = hidden_ability ? Color.new(226, 202, 190) : light_shadow
    if ability
      textpos.push([ability.name, 142, 292, :left, ability_base, ability_shadow])
      drawTextEx(overlay, 16, 322, 488, 2, ability.description, base, dark_shadow)
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw HP bar
    if @pokemon.hp > 0
      w = @pokemon.hp * 96 / @pokemon.totalhp.to_f
      w = 1 if w < 1
      w = ((w / 2).round) * 2
      hpzone = 0
      hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
      hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
      imagepos = [
        ["Graphics/UI/Summary/overlay_hp", 402, 74, 0, hpzone * 6, w, 6]
      ]
      pbDrawImagePositions(overlay, imagepos)
    end
  end

  def drawPageFour
    overlay = @sprites["overlay"].bitmap
    moveBase   = BLACK_TEXT_BASE
    moveShadow = Color.new(196, 202, 202)
    ppBase   = [moveBase,                   # More than 1/2 of total PP
                Color.new(239, 222, 0),     # 1/2 of total PP or less
                Color.new(255, 148, 0),     # 1/4 of total PP or less
                Color.new(239, 0, 0)]       # Zero PP
    ppShadow = [moveShadow,                 # More than 1/2 of total PP
                Color.new(255, 247, 140),   # 1/2 of total PP or less
                Color.new(255, 239, 115),   # 1/4 of total PP or less
                Color.new(247, 222, 156)]   # Zero PP
    @sprites["pokemon"].visible  = true
    @sprites["pokeicon"].visible = false
    textpos  = []
    imagepos = []
    # Write move names, types and PP amounts for each known move
    yPos = 48
    Pokemon::MAX_MOVES.times do |i|
      move = @pokemon.moves[i]
      if move
        move_shortName = (move.name.length > 14) ? move.name[0..12] + "..." : move.name
        type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
        imagepos.push([_INTL("Graphics/UI/types"), 262, yPos - 6, 0, type_number * 28, 64, 28])
        textpos.push([move_shortName, 330, yPos, :left, moveBase, moveShadow])
        textpos.push([_INTL("PP"), 416, yPos + 28, :left, moveBase, moveShadow])
        if move.total_pp > 0
          ppfraction = 0
          if move.pp == 0
            ppfraction = 3
          elsif move.pp * 4 <= move.total_pp
            ppfraction = 2
          elsif move.pp * 2 <= move.total_pp
            ppfraction = 1
          end
          textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 504, yPos + 28, :right, ppBase[ppfraction], ppShadow[ppfraction]])
        end
      else
        textpos.push(["-", 330, yPos, :left, moveBase, moveShadow])
        textpos.push(["--", 444, yPos + 28, :right, moveBase, moveShadow])
      end
      yPos += 64
    end
    # Draw all text and images
    pbDrawTextPositions(overlay, textpos)
    pbDrawImagePositions(overlay, imagepos)
  end

  def drawPageFourSelecting(move_to_learn)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    overlay_cmdinfo = @sprites["overlay_cmdinfo"].bitmap
    overlay_cmdinfo.clear
    writePageCommandInfo(overlay_cmdinfo, move_to_learn ? "Forget" : "Switch", 428, 6, 
    Color.new(248, 248, 248), Color.new(96, 96, 96))
    moveBase   = BLACK_TEXT_BASE
    moveShadow = Color.new(196, 202, 202)
    ppBase   = [moveBase,                   # More than 1/2 of total PP
                Color.new(239, 222, 0),     # 1/2 of total PP or less
                Color.new(255, 148, 0),     # 1/4 of total PP or less
                Color.new(239, 0, 0)]       # Zero PP
    ppShadow = [moveShadow,                 # More than 1/2 of total PP
                Color.new(255, 247, 140),   # 1/2 of total PP or less
                Color.new(255, 239, 115),   # 1/4 of total PP or less
                Color.new(247, 222, 156)]   # Zero PP
    # Set background image
    if move_to_learn
      @sprites["background"].setBitmap("Graphics/UI/Summary/bg_learnmove")
    else
      @sprites["background"].setBitmap("Graphics/UI/Summary/bg_movedetail")
    end
    # Write various bits of text
    textpos = [
      [_INTL("Known Moves"), 8, 6, :left, Color.new(248, 248, 248), Color.new(96, 96, 96)],
      [@pokemon.name, 74, 40, :left, Color.new(248, 248, 248), Color.new(96, 96, 96)],
      [_INTL("Power"), 60, 118, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [_INTL("Accuracy"), 60, 150, :center, LABEL_BASE, LABEL_SHADOW, :outline],
      [_INTL("Effect"), 60, 182, :center, LABEL_BASE, LABEL_SHADOW, :outline]
    ]
    if @pokemon.male?
      textpos.push([_INTL("♂"), 246, 40, :right, Color.new(160, 192, 240), Color.new(48, 80, 200)])
    elsif @pokemon.female?
      textpos.push([_INTL("♀"), 246, 40, :right, Color.new(259, 189, 115), Color.new(231, 8, 8)])
    end
    imagepos = []
    drawShinyOverlay(overlay, 2, @pokemon.shiny?)
    imagepos.push(["Graphics/UI/shiny", 214, 42]) if @pokemon.shiny?
    # Write move names, types and PP amounts for each known move
    yPos = 48
    limit = (move_to_learn) ? Pokemon::MAX_MOVES + 1 : Pokemon::MAX_MOVES
    limit.times do |i|
      move = @pokemon.moves[i]
      if i == Pokemon::MAX_MOVES
        move = move_to_learn
        yPos += 10
      end
      if move
        move_shortName = (move.name.length > 14) ? move.name[0..12] + "..." : move.name
        type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
        imagepos.push([_INTL("Graphics/UI/types"), 262, yPos - 6, 0, type_number * 28, 64, 28])
        textpos.push([move_shortName, 330, yPos, :left, moveBase, moveShadow])
        textpos.push([_INTL("PP"), 416, yPos + 28, :left, moveBase, moveShadow])
        if move.total_pp > 0
          ppfraction = 0
          if move.pp == 0
            ppfraction = 3
          elsif move.pp * 4 <= move.total_pp
            ppfraction = 2
          elsif move.pp * 2 <= move.total_pp
            ppfraction = 1
          end
          textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 504, yPos + 28, :right, ppBase[ppfraction], ppShadow[ppfraction]])
        end
      else
        textpos.push(["-", 330, yPos, :left, moveBase, moveShadow])
        textpos.push(["--", 444, yPos + 28, :right, moveBase, moveShadow])
      end
      yPos += 64
    end
    # Draw all text and images
    pbDrawTextPositions(overlay, textpos)
    pbDrawImagePositions(overlay, imagepos)
    # Draw Pokémon's type icon(s)
    @pokemon.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(0, type_number * 28, 64, 28)
      type_x = (@pokemon.types.length == 1) ? 110 : 110 + (72 * i)
      overlay.blt(type_x, 74, @typebitmap.bitmap, type_rect)
    end
    drawPageIcons(true) if !move_to_learn
  end

  def drawSelectedMove(move_to_learn, selected_move)
    # Draw all of page four, except selected move's details
    drawPageFourSelecting(move_to_learn)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    base   = BLACK_TEXT_BASE
    shadow = Color.new(196, 202, 202)
    @sprites["pokemon"].visible = false if @sprites["pokemon"]
    @sprites["pokeicon"].pokemon = @pokemon
    @sprites["pokeicon"].visible = true
    textpos = []
    # Write power and accuracy values for selected move
    case selected_move.display_damage(@pokemon)
    when 0 then textpos.push(["---", 120, 118, :left, base, shadow])   # Status move
    when 1 then textpos.push(["???", 120, 118, :left, base, shadow])   # Variable power move
    else        textpos.push([selected_move.display_damage(@pokemon).to_s, 120, 118, :left, base, shadow])
    end
    if selected_move.display_accuracy(@pokemon) == 0
      textpos.push(["---", 120, 150, :left, base, shadow])
    else
      textpos.push(["#{selected_move.display_accuracy(@pokemon)}%", 120, 150, :left, base, shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw selected move's damage category icon
    imagepos = [["Graphics/UI/category", 180, 114, 0, selected_move.display_category(@pokemon) * 28, 64, 28]]
    pbDrawImagePositions(overlay, imagepos)
    # Draw selected move's description
    drawTextEx(overlay, 8, 212, 230, 5, selected_move.description, base, shadow)
  end

  def pbMarking(pokemon)
    @sprites["markingbg"].visible      = true
    @sprites["markingoverlay"].visible = true
    @sprites["markingsel"].visible     = true
    base   = MessageConfig::DARK_TEXT_MAIN_COLOR
    shadow = MessageConfig::DARK_TEXT_SHADOW_COLOR
    ret = pokemon.markings.clone
    markings = pokemon.markings.clone
    mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT
    index = 0
    redraw = true
    markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
    loop do
      # Redraw the markings and text
      if redraw
        @sprites["markingoverlay"].bitmap.clear
        (@markingbitmap_2.bitmap.width / MARK_WIDTH).times do |i|
          markrect.x = i * MARK_WIDTH
          markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
          @sprites["markingoverlay"].bitmap.blt(328 + (64 * (i % 3)), 249 + (32 * (i / 3)),
                                                @markingbitmap_2.bitmap, markrect)
        end
        textpos = [
          [_INTL("Mark {1}", pokemon.name), 404, 216, :center, base, shadow],
          [_INTL("OK"), 328, 310, :left, base, shadow],
          [_INTL("Cancel"), 328, 342, :left, base, shadow]
        ]
        pbDrawTextPositions(@sprites["markingoverlay"].bitmap, textpos)
        redraw = false
      end
      # Reposition the cursor
      @sprites["markingsel"].x = 312 + (64 * (index % 3))
      @sprites["markingsel"].y = 242 + (32 * (index / 3))
      case index
      when 6   # OK
        @sprites["markingsel"].x = 312
        @sprites["markingsel"].y = 304
      when 7   # Cancel
        @sprites["markingsel"].x = 312
        @sprites["markingsel"].y = 336
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        case index
        when 6   # OK
          ret = markings
          break
        when 7   # Cancel
          break
        else
          markings[index] = ((markings[index] || 0) + 1) % mark_variants
          redraw = true
        end
      elsif Input.trigger?(Input::ACTION)
        if index < 6 && markings[index] > 0
          pbPlayDecisionSE
          markings[index] = 0
          redraw = true
        end
      elsif Input.trigger?(Input::UP)
        if index == 7
          index = 6
        elsif index == 6
          index = 3
        elsif index < 3
          index = 7
        else
          index -= 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        if index == 7
          index = 0
        elsif index == 6
          index = 7
        elsif index >= 3
          index = 6
        else
          index += 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::LEFT)
        if index < 6
          index -= 1
          index += 3 if index % 3 == 2
          pbPlayCursorSE
        end
      elsif Input.trigger?(Input::RIGHT)
        if index < 6
          index += 1
          index -= 3 if index % 3 == 0
          pbPlayCursorSE
        end
      end
    end
    @sprites["markingbg"].visible      = false
    @sprites["markingoverlay"].visible = false
    @sprites["markingsel"].visible     = false
    if pokemon.markings != ret
      pokemon.markings = ret
      return true
    end
    return false
  end
end