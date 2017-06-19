pragma solidity ^0.4.11;

import "./RNG.sol";

import "./AccessControl.sol";

import "./ControlledAccess.sol";

/**
 * Represents a prorotype Macroverse Generator, for a single star system according to an
 * adaptation of <http://www.mit.edu/afs.new/sipb/user/sekullbe/furble/planet.txt>.
 */
contract MacroversePrototype is ControlledAccess {
    using RNG for *;

    // There are kinds of stars
    //                 0           1      2             3           4            5
    enum ObjectClass { Supergiant, Giant, MainSequence, WhiteDwarf, NeutronStar, BlackHole }
    // Actual stars have a spectral type
    //                  0      1      2      3      4      5      6
    enum SpectralType { TypeO, TypeB, TypeA, TypeF, TypeG, TypeK, TypeM }
    // Each type has subtypes 0-9, except O which only has 5-9
    
    // This root RandNode provides the seed for the universe.
    RNG.RandNode root;
    
    // This AccessControl contract determines who has paid to use the generator contract.
    AccessControl accessControl;
    
    /**
     * Deploy a new copy of the Macroverse prototype contract. Use the given seed to generate the star system.
     * Use the contract at the given address to regulate access.
     */
    function MacroversePrototype(bytes32 baseSeed, address accessControlAddress) ControlledAccess(AccessControl(accessControlAddress)) {
        root = RNG.RandNode(baseSeed);
    }
    
    /**
     * What star type is the star?
     */
    function getStarType() constant onlyControlledAccess returns (ObjectClass class, SpectralType spectralType, uint8 subtype) {
        // Roll 3 distinct d100s
        var roll1 = root.derive("star1").d(1, 100, 0);
        var roll2 = root.derive("star2").d(1, 100, 0);
        var roll3 = root.derive("star3").d(1, 100, 0);
        
        if (roll1 == 1) {
            // Supergiant or giant
            if (roll2 == 1) {
                // Supergiant
                class = ObjectClass.Supergiant;
                if (roll3 <= 10) {
                    spectralType = SpectralType.TypeB;
                } else if (roll3 <= 20) {
                    spectralType = SpectralType.TypeA;
                } else if (roll3 <= 40) {
                    spectralType = SpectralType.TypeF;
                } else if (roll3 <= 60) {
                    spectralType = SpectralType.TypeG;
                } else if (roll3 <= 80) {
                    spectralType = SpectralType.TypeK;
                } else {
                    spectralType = SpectralType.TypeM;
                }
            } else {
                // Normal giant
                class = ObjectClass.Giant;
                if (roll2 <= 5) {
                    spectralType = SpectralType.TypeF;
                } else if (roll2 <= 10) {
                    spectralType = SpectralType.TypeG;
                } else if (roll2 <= 55) {
                    spectralType = SpectralType.TypeK;
                } else {
                    spectralType = SpectralType.TypeM;
                }
            }
            // Assign a subtype; no O is possible here so all are 1-10.
            subtype = uint8(root.derive("subtype").d(1, 10, -1));
        } else if (roll1 <= 93) {
            // Main sequence
            class = ObjectClass.MainSequence;
            if (roll2 == 1) {
                // O or B
                if (roll3 == 1) {
                    // O, very rare
                    spectralType = SpectralType.TypeO;
                    // Subtypes are 5-9
                    subtype = uint8(root.derive("subtype").d(1, 5, 4));
                } else {
                    // B, less rare
                    spectralType = SpectralType.TypeB;
                    subtype = uint8(root.derive("subtype").d(1, 10, -1));
                }
            } else {
                if (roll2 <= 3) {
                    // A
                    spectralType = SpectralType.TypeA;
                } else if (roll2 <= 7) {
                    spectralType = SpectralType.TypeF;
                } else if (roll2 <= 15) {
                    spectralType = SpectralType.TypeG;
                } else if (roll2 <= 31) {
                    spectralType = SpectralType.TypeK;
                } else {
                    spectralType = SpectralType.TypeM;
                }
                subtype = uint8(root.derive("subtype").d(1, 10, -1));
            }
        } else {
            if (roll2 <= 99) {
                // White dwarf, no subtype
                class = ObjectClass.WhiteDwarf;
                if (roll2 <= 20) {
                    spectralType = SpectralType.TypeB;
                } else if (roll2 <= 40) {
                    spectralType = SpectralType.TypeA;
                } else if (roll2 <= 60) {
                    spectralType = SpectralType.TypeF;
                } else if (roll2 <= 80) {
                    spectralType = SpectralType.TypeG;
                } else {
                    spectralType = SpectralType.TypeK;
                }
            } else {
                // Neutron star or black hole, no type or subtype
                if (roll3 <= 95) {
                    class = ObjectClass.NeutronStar;
                } else {
                    // Black hole!
                    class = ObjectClass.BlackHole;
                }
            }
        }
    }
    
    /**
     * How many planets does this system have? Caller passes in star info from getStarType(),
     * to save repeated calls to the generator.
     */
    function getPlanetCount(ObjectClass class, SpectralType spectralType) constant onlyControlledAccess returns (uint8 planets) {     
                
        // Roll for having planets
        var have = root.derive("havePlanets").d(1, 100, 0);
        
        // Start with 0 planets
        planets = 0;
        
        // Derive a node for rolling number of planets.
        var node = root.derive("planets");
        
        if (class == ObjectClass.Supergiant && have <= 10) {
            // 10% of supergiants have 1d6 planets
            planets = uint8(node.d(1, 6, 0));
        } else if (class == ObjectClass.Giant && have <= 20) {
            // 20% of giants have 1d6 planets
            planets = uint8(node.d(1, 6, 0));
        } else if (class == ObjectClass.MainSequence) {
            if ((spectralType == SpectralType.TypeO || spectralType == SpectralType.TypeB) && have <= 10) {
                // 10% of O and B stars have 1d10 planets
                planets = uint8(node.d(1, 10, 0));
            } else if (spectralType == SpectralType.TypeA && have <= 50) {
                // 50% of A stars have 1d10 planets
                planets = uint8(node.d(1, 10, 0));
            } else if ((spectralType == SpectralType.TypeF || spectralType == SpectralType.TypeG) && have <= 99) {
                // 99% of F and G stars have 2d6+3 planets.
                planets = uint8(node.d(2, 6, 3));
            } else if (spectralType == SpectralType.TypeK && have <= 99) {
                // 99% of K stars have 2d6 planets
                planets = uint8(node.d(2, 6, 0));
            } else if (spectralType == SpectralType.TypeM && have <= 50) {
                // 50% of M stars have 1d6 planets
                planets = uint8(node.d(1, 6, 0));
            }
        } else if ((class == ObjectClass.WhiteDwarf || class == ObjectClass.NeutronStar || class == ObjectClass.BlackHole) && have <= 10) {
            // 10% of fancy special objects have 1d6/2 planets
            planets = uint8(node.d(1, 6, 0) / 2);
        }
    
    }
    
    // We have 3 zones for orbits: hot, habitable, and cold.
    //               0      1      2
    enum OrbitZone { ZoneA, ZoneB, ZoneC }
    
    /**
     * How many planets are in each zone? A = hot, B = habitable, C = cold.
     */
    function getPlanetsInZone(uint8 planets, OrbitZone zone) constant onlyControlledAccess returns (uint8) {
        if (planets == 0) {
            return 0;
        } else if (planets <= 3) {
            if (zone == OrbitZone.ZoneA) {
                return 0;
            } else if (zone == OrbitZone.ZoneB) {
                return 1;
            } else if (zone == OrbitZone.ZoneC) {
                return planets - 1;
            }
        } else if (planets <= 5) {
            if (zone == OrbitZone.ZoneA) {
                return 1;
            } else if (zone == OrbitZone.ZoneB) {
                return 1;
            } else if (zone == OrbitZone.ZoneC) {
                return planets - 2;
            }
        } else if (planets <= 7) {
            if (zone == OrbitZone.ZoneA) {
                return 1;
            } else if (zone == OrbitZone.ZoneB) {
                return 2;
            } else if (zone == OrbitZone.ZoneC) {
                return planets - 3;
            }
        } else {
            if (zone == OrbitZone.ZoneA) {
                return 2;
            } else if (zone == OrbitZone.ZoneB) {
                return 2;
            } else if (zone == OrbitZone.ZoneC) {
                return planets - 4;
            }
        }
    }
    
    // Planets come in types
    //                0             1      2            3           4       5        6         7
    enum PlanetType { AsteroidBelt, Giant, VaccuumRock, VaccuumIce, Desert, Hostile, Marginal, Earthlike }
    
    /**
     * What is the type of the planet with the given number, in the given zone, around
     * the star with the given class and spectral type? Caller is responsible for 
     * checking that such a planet actually exists. Planet number counts from 0 to
     * getPlanetCount() - 1.
     */
    function getPlanetType(uint8 planet, OrbitZone zone, ObjectClass class, SpectralType spectralType) constant onlyControlledAccess returns (PlanetType planetType) {
    
        // Roll for a type.
        var roll = root.derive("planet").derive(uint256(planet)).d(1, 100, 0);
        
        if (zone == OrbitZone.ZoneA) {
            // In the hot zone
            if (roll <= 5) {
                return PlanetType.AsteroidBelt;
            } else if (roll <= 60) {
                return PlanetType.VaccuumRock;
            } else if (roll <= 70) {
                return PlanetType.Desert;
            } else {
                if (class == ObjectClass.BlackHole || class == ObjectClass.NeutronStar) {
                    // Can't have nice planets
                    return PlanetType.VaccuumIce;
                }
                return PlanetType.Hostile;
            }
        } else if (class == ObjectClass.MainSequence &&
            (spectralType == SpectralType.TypeF || spectralType == SpectralType.TypeG || spectralType == SpectralType.TypeK) &&
            zone == OrbitZone.ZoneB) {
            // Habitable zone around a nice, normal star
            if (roll <= 5) {
                return PlanetType.AsteroidBelt;
            } else if (roll <= 8) {
                return PlanetType.Giant;
            } else if (roll <= 40) {
                return PlanetType.VaccuumRock;
            } else if (roll <= 60) {
                return PlanetType.Desert;
            } else if (roll <= 80) {
                return PlanetType.Hostile;
            } else if (roll <= 90) {
                return PlanetType.Marginal;
            } else {
                return PlanetType.Earthlike;
            }
        } else if (zone == OrbitZone.ZoneB) {
            // Habitable zone around something else
            if (roll <= 5) {
                return PlanetType.AsteroidBelt;
            } else if (roll <= 8) {
                return PlanetType.Giant;
            } else if (roll <= 40) {
                return PlanetType.VaccuumRock;
            } else if (roll <= 70) {
                return PlanetType.Desert;
            } else {
                if (class == ObjectClass.BlackHole || class == ObjectClass.NeutronStar) {
                    // Can't have nice planets
                    return PlanetType.VaccuumIce;
                }
                return PlanetType.Hostile;
            }
        } else if (zone == OrbitZone.ZoneC) {
            // Cold zone
            if (roll <= 5) {
                return PlanetType.AsteroidBelt;
            } else if (roll <= 75) {
                return PlanetType.Giant;
            } else if (roll <= 80) {
                return PlanetType.VaccuumRock;
            } else if (roll <= 95) {
                return PlanetType.VaccuumIce;
            } else {
                if (class == ObjectClass.BlackHole || class == ObjectClass.NeutronStar) {
                    // Can't have nice planets
                    return PlanetType.VaccuumIce;
                }
                return PlanetType.Hostile;
            }
        }
    }
    
    /**
     * Get the diameter of the given planet, in km. Approximated to the nearest 1000, or 10,000 for giants.
     * Asteroid belts do not have a diameter.
     */
    function getPlanetDiameter(uint8 planet, PlanetType planetType) constant onlyControlledAccess returns (uint) {
        // Make a node to roll with.
        var node = root.derive("planet").derive(uint256(planet)).derive("diameter");
        
        if (planetType == PlanetType.AsteroidBelt) {
            return 0;
        } else if (planetType == PlanetType.Giant) {
            return uint(node.d(3, 6, 0)) * 10000;
        } else if (planetType == PlanetType.VaccuumRock || planetType == PlanetType.VaccuumIce) {
            return uint(node.d(1, 10, 0)) * 1000;
        } else if (planetType == PlanetType.Desert) {
            return uint(node.d(2, 6, 2)) * 1000;
        } else if (planetType == PlanetType.Hostile) {
            return uint(node.d(3, 6, 1)) * 1000;
        } else if (planetType == PlanetType.Marginal || planetType == PlanetType.Earthlike) {
            return uint(node.d(2, 6, 5)) * 1000;
        }
    }
    
    /**
     * Get the number of moons that a planet has, given its number and type.
     */
    function getPlanetMoonCount(uint8 planet, PlanetType planetType) constant onlyControlledAccess returns (uint8) {
        // Make a node to roll with.
        var node = root.derive("planet").derive(uint256(planet)).derive("moons");
        
        if (planetType == PlanetType.AsteroidBelt) {
            return 0;
        } else if (planetType == PlanetType.Giant) {
            return uint8(node.d(2, 10, 0));
        } else {
            var roll = node.d(1, 10, 0);
            if (roll <= 4) {
                return 0;
            } else if (roll <= 7) {
                return 1;
            } else if (roll <= 9) {
                return 2;
            } else {
                return 3;
            }
        }
    }
    
    // TODO: Orbital mechanics, orbital periods, density, temperature, and other things that source material only defined for planets at marginal or better.
    // We will need them for all planets.
    

}
 