module Weewar
  class Unit

    SYMBOL_FOR_UNIT = {
      'Trooper' => :linf,
      'Heavy Trooper' => :hinf,
      'Raider' => :raider,
      'Assault Artillery' => :aart,
      'Tank' => :tank,
      'Heavy Tank' => :htank,
      'Berserker' => :bers,
      'Light Artillery' => :lart,
      'Heavy Artillery' => :hart,
      'DFA' => :dfa,
      'Hovercraft' => :hover,
      'Battleship' => :bship,
      'Helicopter' => :heli,
      'Submarine' => :sub,
      'Destroyer' => :dest,
      'Anti Aircraft' =>  :aa,
      'Speedboat' => :sboat,
      'Bomber' =>  :bomber,
      'Jet' => :jet
      }

    TYPE_FOR_SYMBOL = {
      :linf => 'Trooper',
      :hinf => 'Heavy Trooper',
      :raider => 'Raider',
      :tank => 'Tank',
      :htank => 'Heavy Tank',
      :lart => 'Light Artillery',
      :hart => 'Heavy Artillery',
      :hover => 'Hovercraft',
      'Assault Artillery' => :aart,
      :bers => 'Berserker',
      :dfa => 'DFA',
      :bship=> 'Battleship',
      :heli => 'Helicopter',
      :sub => 'Submarine',
      :dest =>'Destroyer',
      :aa=>'Anti Aircraft',
      :sboat=>'Speedboat',
      :bomber=>'Bomber',
      :jet=>'Jet'
    }

    UNIT_CLASSES = {
      :linf => :soft,
      :hinf => :soft,
      :raider => :hard,
      :aart => :hard,
      :tank => :hard,
      :htank => :hard,
      :bers => :hard,
      :lart => :hard,
      :hart => :hard,
      :dfa => :hard,
      :capturing => :soft,
      :hover => :amphibic,
      :bship => :boat,
      :sboat => :speedboat,
      :dest => :boat,
      :sub => :sub,
      :jet => :jet,
      :heli => :air,
      :bomber => :air,
      :aa => :hard
    }

    # TODO: should be taken from the specifications page
    MOBILITY = {
      :linf   => [9],
      :hinf   => [6],
      :sboat  => [12],
      :lart   => [9],
      :raider => [12],
      :hover  => [12],
      :tank   => [9],
      :aa     => [9],
      :aart   => [12],
      :heli   => [15,3],
      :htank  => [7],
      :bers   => [6],
      :hart   => [6],
      :dfa    => [6],
      :bship  => [6],
      :dest   => [12],
      :sub    => [9],
      :jet    => [18,6],
      :bomber => [18,6],
    }

    # TODO: should be taken from the specifications page
    ATTACK_RANGE = {
      :linf   => [1,1],
      :hinf   => [1,1],
      :sboat  => [2,3],
      :lart   => [1,1],
      :raider => [1,1],
      :hover  => [1,1],
      :tank   => [1,1],
      :aa     => [1,3],
      :aart   => [1,2],
      :heli   => [1,1],
      :htank  => [1,1],
      :bers   => [1,1],
      :hart   => [3,4],
      :dfa    => [2,5],
      :bship  => [1,4],
      :dest   => [1,3],
      :sub    => [1,2],
      :jet    => [1,1],
      :bomber => [1,1],
    }

    # TODO: should be taken from the specifications page
    ATTACK_STRENGTH = {
      :linf   => {:hard=>3,:soft=>6,:sub=>0,:boat=>3,:amphibic=>3,:air=>0,:speedboat=>3},
      :hinf   => {:hard=>8,:soft=>6,:sub=>0,:boat=>8,:amphibic=>8,:air=>6,:speedboat=>8},
      :sboat  => {:hard=>6,:soft=>8,:sub=>0,:boat=>6,:amphibic=>16,:air=>6,:speedboat=>10},
      :lart   => {:hard=>4,:soft=>10,:sub=>0,:boat=>4,:amphibic=>4,:air=>0,:speedboat=>4},
      :raider => {:hard=>4,:soft=>10,:sub=>0,:boat=>4,:amphibic=>8,:air=>4,:speedboat=>4},
      :hover  => {:hard=>6,:soft=>10,:sub=>0,:boat=>6,:amphibic=>10,:air=>0,:speedboat=>8},
      :tank   => {:hard=>7,:soft=>10,:sub=>0,:boat=>7,:amphibic=>7,:air=>0,:speedboat=>7},
      :aa     => {:hard=>3,:soft=>8,:sub=>0,:boat=>3,:amphibic=>3,:air=>9,:speedboat=>3},
      :aart   => {:hard=>6,:soft=>8,:sub=>0,:boat=>6,:amphibic=>6,:air=>6,:speedboat=>6},
      :heli   => {:hard=>10,:soft=>16,:sub=>0,:boat=>8,:amphibic=>12,:air=>6,:speedboat=>12},
      :hart   => {:hard=>10,:soft=>12,:sub=>0,:boat=>10,:amphibic=>10,:air=>0,:speedboat=>12},
      :htank  => {:hard=>12,:soft=>10,:sub=>0,:boat=>10,:amphibic=>10,:air=>0,:speedboat=>10},
      :jet    => {:hard=>8,:soft=>6,:sub=>0,:boat=>6,:amphibic=>6,:air=>16,:speedboat=>6},
      :dest   => {:hard=>10,:soft=>10,:sub=>16,:boat=>10,:amphibic=>12,:air=>12,:speedboat=>12},
      :bomber => {:hard=>14,:soft=>14,:sub=>0,:boat=>14,:amphibic=>14,:air=>0,:speedboat=>14},
      :bers   => {:hard=>16,:soft=>14,:sub=>0,:boat=>14,:amphibic=>14,:air=>0,:speedboat=>14},
      :sub    => {:hard=>0,:soft=>0,:sub=>10,:boat=>16,:amphibic=>0,:air=>0,:speedboat=>0},
      :dfa    => {:hard=>14,:soft=>16,:sub=>0,:boat=>14,:amphibic=>14,:air=>0,:speedboat=>14},
      :bship  => {:hard=>14,:soft=>10,:sub=>4,:boat=>14,:amphibic=>14,:air=>6,:speedboat=>14},
    }

    # <Pistos> These need to be checked, I was just going by memory
    UNIT_COSTS = {
      :linf => 75,
      :hinf => 150,
      :raider => 200,
      :tank => 300,
      :hover => 300,
      :htank => 600,
      :lart => 200,
      :aart => 450,
      :hart => 600,
      :dfa => 1200,
      :bers => 900,
      :sboat => 200,
      :dest => 1100,
      :bship => 2000,
      :sub => 1200,
      :jet => 800,
      :heli => 600,
      :bomber => 900,
      :aa => 300,
    }

    # <Pistos> These need to be checked, I was just going by memory
    REPAIR_RATE = {
      :linf => 1,
      :hinf => 1,
      :raider => 2,
      :tank => 2,
      :hover => 2,
      :htank => 2,
      :lart => 1,
      :aart => 2,
      :hart => 1,
      :dfa => 1,
      :bers => 1,
      :sboat => 2,
      :dest => 1,
      :bship => 1,
      :sub => 1,
      :jet => 3,
      :heli => 3,
      :bomber => 3,
      :aa => 1,
    }

    # TODO: should be taken from the specifications page
    DEFENSE_STRENGTH = {
      :linf => 6,
      :hinf => 6,
      :raider => 6,
      :tank => 10,
      :hover => 8,
      :htank => 14,
      :lart => 3,
      :aart => 6,
      :hart => 4,
      :dfa => 4,
      :bers => 14,
      :sboat => 6,
      :dest => 12,
      :bship => 14,
      :sub => 10,
      :jet => 12,
      :heli => 10,
      :bomber => 10,
      :aa => 4
    }


    CAPTURERS = [:linf, :hover, :hinf]

    INFINITY = 99999999
  end
end

