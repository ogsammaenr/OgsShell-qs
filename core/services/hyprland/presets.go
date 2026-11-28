package hyprland

// DefaultBlurConfig returns Hyprland 0.57.2's balanced Kawase blur with sane defaults for all 11 variants.
func DefaultBlurConfig() BlurConfig {
	return BlurConfig{
		Enabled:          true,
		Variant:          "kawase",
		Size:             6,
		Passes:           3,
		IgnoreOpacity:    true,
		NewOptimizations: true,
		Xray:             false,
		Proportional:     false,
		Noise:            0.012,
		Contrast:         0.90,
		Brightness:       1.0,
		Vibrancy:         0.17,
		VibrancyDarkness: 0.0,
		Special:          false,
		Popups:           true,
		Glass: BlurGlassConfig{
			Refraction: 8,
			Size:       48,
			Roughness:  0.45,
		},
		Acrylic: BlurAcrylicConfig{
			Refraction: 20,
			Bulb:       48,
			Clarity:    0.82,
			Aberration: 0.025,
			Tint:       "14eef5ff",
		},
		Drops: BlurDropsConfig{
			Speed: 2.0,
		},
		HeatShimmer: BlurHeatShimmerConfig{
			Speed: 1.0,
		},
		Aurora: BlurAuroraConfig{
			Speed:     1.0,
			Intensity: 0.35,
			Color1:    "29f0a0ff",
			Color2:    "7a4dffff",
		},
		Haze: BlurHazeConfig{
			Intensity:   0.35,
			Iridescence: 0.70,
		},
		Ripple: BlurRippleConfig{
			Strength: 24,
			Radius:   400,
			Width:    32,
			Duration: 0.45,
		},
		Water: BlurWaterConfig{
			Strength: 24,
			Radius:   20,
			Speed:    0.76,
			Damping:  0.95,
			Duration: 10.0,
		},
		FluidJar: BlurFluidJarConfig{
			Speed:      3.0,
			FillAmount: 0.50,
			Mass:       1.4,
			Precision:  2.0,
			Turbulence: 1.2,
			Distortion: 6.0,
			Color:      "cc3399ff",
		},
	}
}

func BuiltinAppearancePresets() []AppearancePreset {
	baseBlur := DefaultBlurConfig()

	acrylicBlur := DefaultBlurConfig()
	acrylicBlur.Variant = "acrylic"
	acrylicBlur.Size = 7
	acrylicBlur.Passes = 3

	sharpBlur := DefaultBlurConfig()
	sharpBlur.Enabled = false

	return []AppearancePreset{
		{
			ID:          "minimal",
			Name:        "Minimal",
			Description: "1px ince kenarlık, sıkı boşluklar ve dengeli Kawase blur",
			Builtin:     true,
			Config: AppearanceConfig{
				BorderSize:          1,
				BorderColorMode:     "theme",
				ActiveBorderColor:   "89b4faff",
				ActiveBorderColor2:  "cba6f7ff",
				BorderGradientAngle: 45,
				InactiveBorderColor: "313244cc",
				GapsIn:              4,
				GapsOut:             1,
				Rounding:            10,
				RoundingPower:       4.0,
				ActiveOpacity:       1.0,
				InactiveOpacity:     0.96,
				ShadowEnabled:       true,
				ShadowRange:         15,
				ShadowPower:         2,
				DimInactive:         false,
				DimStrength:         0.08,
				Blur:                baseBlur,
			},
		},
		{
			ID:          "rounded",
			Name:        "Yuvarlak",
			Description: "14px iOS squircle köşeler, ferah boşluklar ve derin gölge",
			Builtin:     true,
			Config: AppearanceConfig{
				BorderSize:      2,
				GapsIn:          6,
				GapsOut:         10,
				Rounding:        14,
				RoundingPower:   4.0,
				ActiveOpacity:   1.0,
				InactiveOpacity: 0.94,
				ShadowEnabled:   true,
				ShadowRange:     32,
				ShadowPower:     3,
				DimInactive:     false,
				DimStrength:     0.08,
				Blur:            baseBlur,
			},
		},
		{
			ID:          "acrylic_glass",
			Name:        "Akrilik Cam",
			Description: "Hyprland 0.57 Acrylic lens blur, yumuşak saydamlık ve squircle",
			Builtin:     true,
			Config: AppearanceConfig{
				BorderSize:      1,
				GapsIn:          6,
				GapsOut:         10,
				Rounding:        16,
				RoundingPower:   4.0,
				ActiveOpacity:   0.95,
				InactiveOpacity: 0.88,
				ShadowEnabled:   true,
				ShadowRange:     28,
				ShadowPower:     3,
				DimInactive:     false,
				DimStrength:     0.08,
				Blur:            acrylicBlur,
			},
		},
		{
			ID:          "borderless",
			Name:        "Kenarlıksız",
			Description: "0px kenarlık, yalnızca gölge ve yumuşak köşelerle pencere ayrımı",
			Builtin:     true,
			Config: AppearanceConfig{
				BorderSize:      0,
				GapsIn:          7,
				GapsOut:         12,
				Rounding:        12,
				RoundingPower:   3.5,
				ActiveOpacity:   1.0,
				InactiveOpacity: 0.95,
				ShadowEnabled:   true,
				ShadowRange:     36,
				ShadowPower:     3,
				DimInactive:     true,
				DimStrength:     0.08,
				Blur:            baseBlur,
			},
		},
		{
			ID:          "sharp",
			Name:        "Keskin",
			Description: "0px köşe, gölgesiz ve blursuz saf tiling üretkenlik modu",
			Builtin:     true,
			Config: AppearanceConfig{
				BorderSize:      2,
				GapsIn:          2,
				GapsOut:         4,
				Rounding:        0,
				RoundingPower:   2.0,
				ActiveOpacity:   1.0,
				InactiveOpacity: 0.96,
				ShadowEnabled:   false,
				ShadowRange:     0,
				ShadowPower:     2,
				DimInactive:     false,
				DimStrength:     0.05,
				Blur:            sharpBlur,
			},
		},
	}
}

func BuiltinAnimationPresets() []AnimationPreset {
	return []AnimationPreset{
		{
			ID:          "macos",
			Name:        "macOS",
			Description: "Akıcı easeOutQuint popin ve ipeksi yatay çalışma alanı geçişi",
			Builtin:     true,
			Config: AnimationsConfig{
				Enabled:     true,
				WindowsIn:   AnimationLeaf{Enabled: true, Speed: 4.2, Bezier: "easeOutQuint", Style: "popin 88%"},
				WindowsOut:  AnimationLeaf{Enabled: true, Speed: 3.5, Bezier: "easeInOutCubic", Style: "popin 88%"},
				WindowsMove: AnimationLeaf{Enabled: true, Speed: 4.5, Bezier: "easeOutQuint", Style: ""},
				Workspaces:  AnimationLeaf{Enabled: true, Speed: 4.8, Bezier: "easeOutQuint", Style: "slidefade 18%"},
				Layers:      AnimationLeaf{Enabled: true, Speed: 3.6, Bezier: "easeOutQuint", Style: "popin 85%"},
				Fade:        AnimationLeaf{Enabled: true, Speed: 3.2, Bezier: "almostLinear", Style: ""},
				Border:      AnimationLeaf{Enabled: true, Speed: 5.0, Bezier: "easeOutQuint", Style: ""},
			},
		},
		{
			ID:          "smooth",
			Name:        "Akıcı",
			Description: "Dengeli easeOutExpo hareketleri, sıfır sekme",
			Builtin:     true,
			Config: AnimationsConfig{
				Enabled:     true,
				WindowsIn:   AnimationLeaf{Enabled: true, Speed: 4.6, Bezier: "easeOutExpo", Style: "popin 82%"},
				WindowsOut:  AnimationLeaf{Enabled: true, Speed: 4.0, Bezier: "easeOutExpo", Style: "popin 82%"},
				WindowsMove: AnimationLeaf{Enabled: true, Speed: 4.8, Bezier: "easeOutExpo", Style: ""},
				Workspaces:  AnimationLeaf{Enabled: true, Speed: 5.0, Bezier: "smoothSlide", Style: "slide"},
				Layers:      AnimationLeaf{Enabled: true, Speed: 3.8, Bezier: "easeOutExpo", Style: "fade"},
				Fade:        AnimationLeaf{Enabled: true, Speed: 3.5, Bezier: "almostLinear", Style: ""},
				Border:      AnimationLeaf{Enabled: true, Speed: 4.5, Bezier: "easeOutExpo", Style: ""},
			},
		},
		{
			ID:          "snappy",
			Name:        "Hızlı",
			Description: "Anlık tepkili, düşük gecikmeli keskin geçişler",
			Builtin:     true,
			Config: AnimationsConfig{
				Enabled:     true,
				WindowsIn:   AnimationLeaf{Enabled: true, Speed: 2.5, Bezier: "snappyQuick", Style: "popin 90%"},
				WindowsOut:  AnimationLeaf{Enabled: true, Speed: 2.2, Bezier: "snappyQuick", Style: "popin 90%"},
				WindowsMove: AnimationLeaf{Enabled: true, Speed: 2.8, Bezier: "quick", Style: ""},
				Workspaces:  AnimationLeaf{Enabled: true, Speed: 2.8, Bezier: "snappyQuick", Style: "slide"},
				Layers:      AnimationLeaf{Enabled: true, Speed: 2.2, Bezier: "quick", Style: "fade"},
				Fade:        AnimationLeaf{Enabled: true, Speed: 2.0, Bezier: "quick", Style: ""},
				Border:      AnimationLeaf{Enabled: true, Speed: 3.0, Bezier: "quick", Style: ""},
			},
		},
		{
			ID:          "bouncy",
			Name:        "Yaylı",
			Description: "Fiziksel spring ve overshoot ile canlı sekme hissiyatı",
			Builtin:     true,
			Config: AnimationsConfig{
				Enabled:     true,
				WindowsIn:   AnimationLeaf{Enabled: true, Speed: 4.8, Bezier: "easeOutBack", Style: "popin 80%"},
				WindowsOut:  AnimationLeaf{Enabled: true, Speed: 3.8, Bezier: "overshoot", Style: "popin 80%"},
				WindowsMove: AnimationLeaf{Enabled: true, Speed: 5.0, Bezier: "springBouncy", Style: ""},
				Workspaces:  AnimationLeaf{Enabled: true, Speed: 5.2, Bezier: "overshoot", Style: "slide"},
				Layers:      AnimationLeaf{Enabled: true, Speed: 4.2, Bezier: "easeOutBack", Style: "popin 80%"},
				Fade:        AnimationLeaf{Enabled: true, Speed: 3.5, Bezier: "almostLinear", Style: ""},
				Border:      AnimationLeaf{Enabled: true, Speed: 5.0, Bezier: "overshoot", Style: ""},
			},
		},
		{
			ID:          "gentle",
			Name:        "Sakin",
			Description: "Yavaş, yumuşak springSoft süzülme efektleri",
			Builtin:     true,
			Config: AnimationsConfig{
				Enabled:     true,
				WindowsIn:   AnimationLeaf{Enabled: true, Speed: 6.0, Bezier: "springSoft", Style: "popin 86%"},
				WindowsOut:  AnimationLeaf{Enabled: true, Speed: 5.5, Bezier: "gentle", Style: "popin 86%"},
				WindowsMove: AnimationLeaf{Enabled: true, Speed: 6.0, Bezier: "springGentle", Style: ""},
				Workspaces:  AnimationLeaf{Enabled: true, Speed: 6.2, Bezier: "gentle", Style: "slidefade 20%"},
				Layers:      AnimationLeaf{Enabled: true, Speed: 5.0, Bezier: "gentle", Style: "fade"},
				Fade:        AnimationLeaf{Enabled: true, Speed: 4.5, Bezier: "gentle", Style: ""},
				Border:      AnimationLeaf{Enabled: true, Speed: 6.0, Bezier: "gentle", Style: ""},
			},
		},
		{
			ID:          "disabled",
			Name:        "Kapalı",
			Description: "Tüm pencere ve masaüstü animasyonlarını kapatır",
			Builtin:     true,
			Config: AnimationsConfig{
				Enabled:     false,
				WindowsIn:   AnimationLeaf{Enabled: false, Speed: 1.0, Bezier: "linear", Style: "popin 85%"},
				WindowsOut:  AnimationLeaf{Enabled: false, Speed: 1.0, Bezier: "linear", Style: "popin 85%"},
				WindowsMove: AnimationLeaf{Enabled: false, Speed: 1.0, Bezier: "linear", Style: ""},
				Workspaces:  AnimationLeaf{Enabled: false, Speed: 1.0, Bezier: "linear", Style: "slide"},
				Layers:      AnimationLeaf{Enabled: false, Speed: 1.0, Bezier: "linear", Style: "fade"},
				Fade:        AnimationLeaf{Enabled: false, Speed: 1.0, Bezier: "linear", Style: ""},
				Border:      AnimationLeaf{Enabled: false, Speed: 1.0, Bezier: "linear", Style: ""},
			},
		},
	}
}

func DefaultUnifiedConfig() HyprUnifiedConfig {
	appPresets := BuiltinAppearancePresets()
	animPresets := BuiltinAnimationPresets()
	return HyprUnifiedConfig{
		ActiveAppearancePreset:  appPresets[0].ID,
		ActiveAnimationPreset:   animPresets[0].ID,
		GameMode:                false,
		Appearance:              appPresets[0].Config,
		Animations:              animPresets[0].Config,
		CustomAppearancePresets: []AppearancePreset{},
		CustomAnimationPresets:  []AnimationPreset{},
	}
}
