package edu.uncc.astrobotics.navProtoControls.config;

public class ButtonConfig {
	private String label;
	private String code;

	@Override
	public String toString() {
		return "ButtonConfig [label=" + label + ", code=" + code + "]";
	}

	public String getLabel() {
		return label;
	}

	public void setLabel(String label) {
		this.label = label;
	}

	public String getCode() {
		return code;
	}

	public void setCode(String code) {
		this.code = code;
	}
}
