package edu.uncc.astrobotics.navProtoControls.config;

public class CheckboxConfig {
	private String label;
	private String variable;
	private boolean defaultValue;

	public String getLabel() {
		return label;
	}

	public void setLabel(String label) {
		this.label = label;
	}

	@Override
	public String toString() {
		return "CheckboxConfig [label=" + label + ", variable=" + variable + ", defaultValue=" + defaultValue + "]";
	}

	public String getVariable() {
		return variable;
	}

	public void setVariable(String variable) {
		this.variable = variable;
	}

	public boolean getDefaultValue() {
		return defaultValue;
	}

	public void setDefaultValue(boolean defaultValue) {
		this.defaultValue = defaultValue;
	}
}
