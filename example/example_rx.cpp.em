/** \file example_rx.cpp
 *  \brief Example of using ibisami to build a Rx model.
 *
 * Original author: David Banas <br>
 * Original date:   May 20, 2015
 *
 * Copyright (c) 2015 David Banas; all rights reserved World wide.
 */

#include <string>
#include <vector>
#include "include/ami_rx.h"

#define PI 3.14159
#define RX_BW 30.0e9
#define CTLE_DC_GAIN 1.0
#define DFE_DUMP_FILE "example_rx_dfe_dump.csv"
#define DFE_INPUT_FILE "example_rx_dfe_input.csv"

/// An example device specific Rx model implementation.
class MyRx : public AmiRx {
    typedef AmiRx inherited;

 public:
    /// Constructor
    MyRx() { }

    /// Destructor
    ~MyRx() { }

    /// Initializer
    void init(double *impulse_matrix, const long number_of_rows,
            const long aggressors, const double sample_interval,
            const double bit_time, const std::string& AMI_parameters_in) override {
        // Let our base class do its thing.
        inherited::init(impulse_matrix, number_of_rows, aggressors,
            sample_interval, bit_time, AMI_parameters_in);

        // Grab our parameters and configure things accordingly.
        std::vector<std::string> node_names; node_names.clear();
        std::ostringstream msg;

        msg << "Initializing Rx...\n";

@{
from pyibisami import ami_config as ac

for pname in ami_params['model']:
    ac.print_code(pname, ami_params['model'][pname])
}

        if (ctle_mode) {
            // Calculate the zero and poles needed to meet the response spec.
            double p2 = -2. * PI * ctle_bandwidth;
            double p1 = -2. * PI * ctle_freq;
            double z  = p1 / pow(10., ctle_mag / 20.);

            // Use matched-z transform to convert them to numerator/denominator of transfer function.
            z = exp(z * sample_interval);
            p1 = exp(p1 * sample_interval);
            p2 = exp(p2 * sample_interval);
            std::vector<double> num = {1.0, -z, 0.0};
            for (auto i = 0; i < num.size(); i++)
                num[i] *= (1 - p1) * (1 - p2) * pow(10., ctle_dcgain / 20.) / (1 - z);
            std::vector<double> den = {1.0, -(p1 + p2), p1 * p2};
            ctle_ = new DigitalFilter(num, den);
            if (!ctle_)
                throw std::runtime_error("ERROR: MyRx::init() could not allocate a DigitalFilter for its CTLE!");
        }

        if (dfe_mode) {
            std::vector<double> tap_weights; tap_weights.clear();
            tap_weights.push_back(dfe_tap1);
            tap_weights.push_back(dfe_tap2);
            tap_weights.push_back(dfe_tap3);
            tap_weights.push_back(dfe_tap4);
            tap_weights.push_back(dfe_tap5);
            dfe_ = new DFE(dfe_vout, dfe_gain, dfe_mode, sample_interval, bit_time, tap_weights);
            if (!dfe_)
                throw std::runtime_error("ERROR: MyRx::init() could not allocate a DFE!");
            std::vector<double> max_weights {0.5, 0.4, 0.3, 0.2, 0.1};
            std::vector<double> min_weights {-0.5, -0.4, -0.3, -0.2, -0.1};
            dfe_->set_max_weights(max_weights);
            dfe_->set_min_weights(min_weights);
        }

        if (dbg_enable) {
            if (dump_dfe_adaptation_) {
                dfe_dump_file_ = DFE_DUMP_FILE;
            }
            if (dump_adaptation_input_) {
                dfe_input_file_ = DFE_INPUT_FILE;
            }
        }

        // Fill in message string.
        msg << "ibisami example Rx model was configured successfully, as follows:\n";
        if (ctle_mode)
            msg << "\tCTLE: " << ctle_mag << " dB boost at " << ctle_freq / 1.0e9 << " GHz\n";
        else
            msg << "\tCTLE: not present\n";
        if (dfe_mode) {
            msg << "\tDFE: mode: " << dfe_mode << "  vout: " << dfe_vout << "  gain: " << dfe_gain << "\n";
            std::vector<double> tmp_weights = dfe_->get_weights();
            for (auto i = 0; i < dfe_ntaps; i++)
                msg << "\t\ttap" << i + 1 << ": " << tmp_weights[i] << "\n";
        }
        else
            msg << "\tDFE: not present\n";
        msg_ += msg.str();
    }
} my_rx;

AMIModel *ami_model = &my_rx;  ///< The pointer required by the API implementation.

