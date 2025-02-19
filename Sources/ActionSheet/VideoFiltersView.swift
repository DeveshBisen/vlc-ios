/*****************************************************************************
 * VideoFiltersView.swift
 *
 * Copyright © 2020 VLC authors and VideoLAN
 * Copyright © 2020 Videolabs
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol VideoFiltersViewDelegate: AnyObject {
    func videoFiltersViewShowIcon()
    func videoFiltersViewHideIcon()
}

class VideoFiltersView: UIView {

    @IBOutlet weak var brightnessLabel: UILabel!
    @IBOutlet weak var brightnessSlider: VLCSlider!
    @IBOutlet weak var contrastLabel: UILabel!
    @IBOutlet weak var contrastSlider: VLCSlider!
    @IBOutlet weak var hueLabel: UILabel!
    @IBOutlet weak var hueSlider: VLCSlider!
    @IBOutlet weak var saturationLabel: UILabel!
    @IBOutlet weak var saturationSlider: VLCSlider!
    @IBOutlet weak var gammaLabel: UILabel!
    @IBOutlet weak var gammaSlider: VLCSlider!
    private let resetButton = UIButton()

    private let defaultBrightness: Float = 1.0
    private let defaultContrast: Float = 1.0
    private let defaultHue: Float = 0.0
    private let defaultSaturation: Float = 1.0
    private let defaultGamma: Float = 1.0

    private let minValue: Float = 0.0
    private let minHue: Float = -180.0
    private let maxBrightness: Float = 2.0
    private let maxContrast: Float = 2.0
    private let maxHue: Float = 180.0
    private let maxSaturation: Float = 3.0
    private let maxGamma: Float = 10.0

    private var currentBrightness: Float = 1.0
    private var currentContrast: Float = 1.0
    private var currentHue: Float = 0.0
    private var currentSaturation: Float = 1.0
    private var currentGamma: Float = 1.0

    weak var delegate: VideoFiltersViewDelegate?

    let vpc = PlaybackService.sharedInstance()


    override func awakeFromNib() {
        setupLabels()
        setupResetButton()
        setupSliders()
        setupTheme()
    }

    private func setupTheme() {
        brightnessLabel.textColor = PresentationTheme.darkTheme.colors.cellTextColor
        contrastLabel.textColor = PresentationTheme.darkTheme.colors.cellTextColor
        hueLabel.textColor = PresentationTheme.darkTheme.colors.cellTextColor
        saturationLabel.textColor = PresentationTheme.darkTheme.colors.cellTextColor
        gammaLabel.textColor = PresentationTheme.darkTheme.colors.cellTextColor
        resetButton.setTitleColor(PresentationTheme.darkTheme.colors.orangeUI, for: .normal)
        resetButton.setTitleColor(PresentationTheme.darkTheme.colors.orangeUI.withAlphaComponent(0.5), for: .highlighted)
    }

    private func setupLabels() {
        brightnessLabel.text = NSLocalizedString("VFILTER_BRIGHTNESS", comment: "")
        contrastLabel.text = NSLocalizedString("VFILTER_CONTRAST", comment: "")
        hueLabel.text = NSLocalizedString("VFILTER_HUE", comment: "")
        saturationLabel.text = NSLocalizedString("VFILTER_SATURATION", comment: "")
        gammaLabel.text = NSLocalizedString("VFILTER_GAMMA", comment: "")
    }

    private func setupResetButton() {
        resetButton.setTitle(NSLocalizedString("BUTTON_RESET", comment: ""), for: .normal)
        resetButton.accessibilityLabel = NSLocalizedString("VIDEO_FILTER_RESET_BUTTON", comment: "")
        resetButton.titleLabel?.font = .systemFont(ofSize: 17.0, weight: .semibold)
        resetButton.addTarget(self, action: #selector(self.handleResetButton(_:)), for: .touchUpInside)
        resetButton.setContentHuggingPriority(.required, for: .horizontal)
        resetButton.setContentHuggingPriority(.required, for: .vertical)
        resetButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setupSliders() {
        brightnessSlider.minimumValue = minValue
        brightnessSlider.maximumValue = maxBrightness
        brightnessSlider.tintColor = PresentationTheme.darkTheme.colors.orangeUI
        brightnessSlider.setValue(currentBrightness, animated: true)

        contrastSlider.minimumValue = minValue
        contrastSlider.maximumValue = maxContrast
        contrastSlider.tintColor = PresentationTheme.darkTheme.colors.orangeUI
        contrastSlider.setValue(currentContrast, animated: true)

        hueSlider.minimumValue = minHue
        hueSlider.maximumValue = maxHue
        hueSlider.tintColor = PresentationTheme.darkTheme.colors.orangeUI
        hueSlider.setValue(currentHue, animated: true)

        saturationSlider.minimumValue = minValue
        saturationSlider.maximumValue = maxSaturation
        saturationSlider.tintColor = PresentationTheme.darkTheme.colors.orangeUI
        saturationSlider.setValue(currentSaturation, animated: true)

        gammaSlider.minimumValue = minValue
        gammaSlider.maximumValue = maxGamma
        gammaSlider.tintColor = PresentationTheme.darkTheme.colors.orangeUI
        gammaSlider.setValue(currentGamma, animated: true)
    }

    func resetSlidersIfNeeded() {
        if vpc.brightness != currentBrightness ||
            vpc.contrast != currentContrast ||
            vpc.hue != currentHue ||
            vpc.saturation != currentSaturation ||
            vpc.gamma != currentGamma {
            currentBrightness = defaultBrightness
            currentContrast = defaultContrast
            currentHue = defaultHue
            currentSaturation = defaultSaturation
            currentGamma = defaultGamma

            setupSliders()

            delegate?.videoFiltersViewHideIcon()
        }
    }

    @IBAction func handleSliderChange(_ sender: VLCSlider) {
        if sender.tag == 1 {
            currentBrightness = sender.value
            brightnessSlider.setValue(currentBrightness, animated: true)
            vpc.brightness = currentBrightness
        } else if sender.tag == 2 {
            currentContrast = sender.value
            contrastSlider.setValue(currentContrast, animated: true)
            vpc.contrast = currentContrast
        } else if sender.tag == 3 {
            currentHue = sender.value
            hueSlider.setValue(currentHue, animated: true)
            vpc.hue = currentHue
        } else if sender.tag == 4 {
            currentSaturation = sender.value
            saturationSlider.setValue(currentSaturation, animated: true)
            vpc.saturation = currentSaturation
        } else if sender.tag == 5 {
            currentGamma = sender.value
            gammaSlider.setValue(currentGamma, animated: true)
            vpc.gamma = currentGamma
        }

        delegate?.videoFiltersViewShowIcon()
    }

    func reset() {
        currentBrightness = defaultBrightness
        brightnessSlider.setValue(currentBrightness, animated: true)
        vpc.brightness = currentBrightness

        currentContrast = defaultContrast
        contrastSlider.setValue(currentContrast, animated: true)
        vpc.contrast = currentContrast

        currentHue = defaultHue
        hueSlider.setValue(currentHue, animated: true)
        vpc.hue = currentHue

        currentSaturation = defaultSaturation
        saturationSlider.setValue(currentSaturation, animated: true)
        vpc.saturation = currentSaturation

        currentGamma = defaultGamma
        gammaSlider.setValue(currentGamma, animated: true)
        vpc.gamma = currentGamma
    }

    @objc func handleResetButton(_ sender: UIButton) {
        reset()

        delegate?.videoFiltersViewHideIcon()
    }
}

extension VideoFiltersView: ActionSheetAccessoryViewsDelegate {
    func actionSheetAccessoryViews(_ actionSheet: ActionSheetSectionHeader) -> [UIView] {
        return [resetButton]
    }
}
