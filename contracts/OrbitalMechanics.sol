pragma solidity ^0.4.18;

import "./RealMath.sol";

/**
 * Provides methods for doing orbital mechanics calculations, based on RealMath.
 */
contract OrbitalMechanics {
    using RealMath for *;

    /**
     * We need the gravitational constant. Calculated by solving the mean
     * motion equation for Earth. We can be mostly precise here, because we
     * know the semimajor axis and year length (in Julian years) to a few
     * places.
     */
    int128 constant REAL_G_PER_SOL = 145919349250077040774785972305920;

    /**
     * It is also useful to have Pi around.
     * We can't pull it in from the library.
     */
    int128 constant REAL_PI = 3454217652358;

    /**
     * And two pi, which happens to be odd in its most accurate representation.
     */
    int128 constant REAL_TWO_PI = 6908435304715;

    /**
     * A "year" is 365.25 days. We use Julian years.
     */
    int128 constant REAL_SECONDS_PER_YEAR = 34697948144703898000;


    // Functions for orbital mechanics. Maybe should be a library?
    // Are NOT controlled access, since they don't talk to the RNG.
    // Please don't do these in Solidity unless you have to; you can do orbital mechanics in JS just fine with actual floats.
    // The steps to compute an orbit are:
    // 
    // 1. Compute the semimajor axis as (apoapsis + periapsis) / 2 (do this yourself)
    // 2. Compute the mean angular motion, n = sqrt(central mass * gravitational constant / semimajor axis^3)
    // 3. Compute the Mean Anomaly, as n * time since epoch + MA at epoch, and wrap to an angle 0 to 2 pi
    // 4. Compute the Eccentric Anomaly numerically to solve MA = EA - eccentricity * sin(ea)
    // 5. Compute the True Anomaly as 2 * atan2(sqrt((1 + eccentricity) / (1 - eccentricity)) * tan(EA/2))
    // 6. Compute the current radius as r = semimajor * (1 - eccentricity^2) / (1 + eccentricity * cos(TA))
    // 7. Compute Cartesian X (toward longitude 0) = radius * (cos(LAN) * cos(AOP + TA) - sin(LAN) * sin(AOP + TA) * cos(inclination))
    // 8. Compute Cartesian Y (in plane) = radius * (sin(LAN) * cos(AOP + TA) + cos(LAN) * sin(AOP + TA) * cos(inclination))
    // 9. Compute Cartesian Z (above plane) = radius * sin(inclination) * sin(AOP + TA)


    /**
     * Compute the mean angular motion, in radians per Julian year (365.25
     * days), given a star mass in sols and a semimajor axis in meters.
     */
    function computeMeanAngularMotion(int128 real_central_mass_in_sols, int128 real_semimajor_axis) public pure returns (int128) {
        // REAL_G_PER_SOL is big, but nothing masses more than 100s of sols, so we can do the multiply.
        // But the semimajor axis in meters may be very big so we can't really do the cube for the denominator.
        // And since values in radians per second are tiny, their squares are even tinier and probably out of range.
        // So we scale up to radians per year
        return real_central_mass_in_sols.mul(REAL_G_PER_SOL)
            .div(real_semimajor_axis)
            .mul(REAL_SECONDS_PER_YEAR)
            .div(real_semimajor_axis)
            .mul(REAL_SECONDS_PER_YEAR).div(real_semimajor_axis).sqrt();
    }

    /**
     * Compute the mean anomaly, from 0 to 2 PI, given the mean anomaly at
     * epoch, mean angular motion (in radians per Julian year) and the time (in
     * Julian years) since epoch.
     */
    function computeMeanAnomaly(int128 real_mean_anomaly_at_epoch, int128 real_mean_angular_motion, int128 real_years_since_epoch) public pure returns (int128) {
        return (real_mean_anomaly_at_epoch + real_mean_angular_motion.mul(real_years_since_epoch)) % REAL_TWO_PI;
    }
    
}
