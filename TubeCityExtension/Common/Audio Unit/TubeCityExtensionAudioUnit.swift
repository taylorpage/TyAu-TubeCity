//
//  TubeCityExtensionAudioUnit.swift
//  TubeCityExtension
//
//  Created by Taylor Page on 1/22/26.
//

import AVFoundation

public class TubeCityExtensionAudioUnit: AUAudioUnit, @unchecked Sendable
{
	// C++ Objects
	var kernel = TubeCityExtensionDSPKernel()
    var processHelper: AUProcessHelper?
    var inputBus = BufferedInputBus()

	private var outputBus: AUAudioUnitBus?
    private var _inputBusses: AUAudioUnitBusArray!
    private var _outputBusses: AUAudioUnitBusArray!

    // Timer for updating signal level meter
    private var meterUpdateTimer: Timer?

	@objc override init(componentDescription: AudioComponentDescription, options: AudioComponentInstantiationOptions) throws {
		let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
		try super.init(componentDescription: componentDescription, options: options)
		outputBus = try AUAudioUnitBus(format: format)
        outputBus?.maximumChannelCount = 8
        
        // Create the input and output busses.
        inputBus.initialize(format, 8);

        // Create the input and output bus arrays.
        _inputBusses = AUAudioUnitBusArray(audioUnit: self, busType: AUAudioUnitBusType.input, busses: [inputBus.bus!])
        
        // Create the input and output bus arrays.
		_outputBusses = AUAudioUnitBusArray(audioUnit: self, busType: AUAudioUnitBusType.output, busses: [outputBus!])
        
        processHelper = AUProcessHelper(&kernel, &inputBus)
	}

    public override var inputBusses: AUAudioUnitBusArray {
        return _inputBusses
    }

    public override var outputBusses: AUAudioUnitBusArray {
        return _outputBusses
    }
    
    public override var channelCapabilities: [NSNumber]? {
        // Explicitly declare mono and stereo support
        // Format: [inputChannels, outputChannels, inputChannels, outputChannels, ...]
        return [
            1, 1,  // Mono in, Mono out
            2, 2   // Stereo in, Stereo out
        ] as [NSNumber]
    }

    public override var  maximumFramesToRender: AUAudioFrameCount {
        get {
            return kernel.maximumFramesToRender()
        }

        set {
            kernel.setMaximumFramesToRender(newValue)
        }
    }

    // MARK: - Rendering
    public override var internalRenderBlock: AUInternalRenderBlock {
        return processHelper!.internalRenderBlock()
    }

    // Allocate resources required to render.
    // Subclassers should call the superclass implementation.
    public override func allocateRenderResources() throws {
        let inputChannelCount = self.inputBusses[0].format.channelCount
        let outputChannelCount = self.outputBusses[0].format.channelCount

        if outputChannelCount != inputChannelCount {
            setRenderResourcesAllocated(false)
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioUnitErr_FailedInitialization), userInfo: nil)
        }

        inputBus.allocateRenderResources(self.maximumFramesToRender);

		kernel.setMusicalContextBlock(self.musicalContextBlock)
        kernel.initialize(Int32(inputChannelCount), Int32(outputChannelCount), outputBus!.format.sampleRate)

        processHelper?.setChannelCount(inputChannelCount, outputChannelCount)

        // Start timer to update signal level meter for UI
        startMeterUpdateTimer()

		try super.allocateRenderResources()
	}

    // Deallocate resources allocated in allocateRenderResourcesAndReturnError:
    // Subclassers should call the superclass implementation.
    public override func deallocateRenderResources() {

        // Stop meter update timer
        stopMeterUpdateTimer()

        // Deallocate your resources.
        kernel.deInitialize()

        super.deallocateRenderResources()
    }

	public func setupParameterTree(_ parameterTree: AUParameterTree) {
		self.parameterTree = parameterTree

		// Set the Parameter default values before setting up the parameter callbacks
		for param in parameterTree.allParameters {
            kernel.setParameter(param.address, param.value)
		}

		setupParameterCallbacks()
	}

	private func setupParameterCallbacks() {
		// implementorValueObserver is called when a parameter changes value.
		parameterTree?.implementorValueObserver = { [weak self] param, value -> Void in
            self?.kernel.setParameter(param.address, value)
		}

		// implementorValueProvider is called when the value needs to be refreshed.
		parameterTree?.implementorValueProvider = { [weak self] param in
            return self!.kernel.getParameter(param.address)
		}

		// A function to provide string representations of parameter values.
		parameterTree?.implementorStringFromValueCallback = { param, valuePtr in
			guard let value = valuePtr?.pointee else {
				return "-"
			}
			return NSString.localizedStringWithFormat("%.f", value) as String
		}
	}

    // MARK: - Signal Level Metering

    private func startMeterUpdateTimer() {
        // Update meter at ~30 Hz for smooth visual feedback.
        // Must be scheduled on the main run loop — allocateRenderResources can be
        // called from a background thread, and a Timer on a background run loop
        // that never runs will never fire.
        DispatchQueue.main.async {
            self.meterUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
                self?.updateSignalLevelParameter()
            }
        }
    }

    private func stopMeterUpdateTimer() {
        meterUpdateTimer?.invalidate()
        meterUpdateTimer = nil
    }

    private func updateSignalLevelParameter() {
        guard let parameterTree = parameterTree,
              let signalLevelParam = parameterTree.parameter(withAddress: TubeCityExtensionParameterAddress.signallevel.rawValue),
              let flickerLevelParam = parameterTree.parameter(withAddress: TubeCityExtensionParameterAddress.flickerlevel.rawValue) else {
            return
        }

        // Use nil originator so the ObservableAUParameter's observer token
        // fires and pushes the value into SwiftUI.  The .value setter passes
        // its own token as originator, which AU suppresses to prevent feedback
        // loops — that works for knobs but kills meter updates.
        signalLevelParam.setValue(kernel.getSignalLevel(), originator: nil)
        flickerLevelParam.setValue(kernel.getParameter(TubeCityExtensionParameterAddress.flickerlevel.rawValue), originator: nil)
    }
}
