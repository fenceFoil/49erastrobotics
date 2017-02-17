package edu.uncc.astrobotics.navProtoControls.config;

public class SliderConfig {
	private double defaultMin, defaultMax, defaultValue;
	private String variable;
	public double getDefaultMin() {
		return defaultMin;
	}
	public void setDefaultMin(double defaultMin) {
		this.defaultMin = defaultMin;
	}
	public double getDefaultMax() {
		return defaultMax;
	}
	public void setDefaultMax(double defaultMax) {
		this.defaultMax = defaultMax;
	}
	public double getDefaultValue() {
		return defaultValue;
	}
	public void setDefaultValue(double defaultValue) {
		this.defaultValue = defaultValue;
	}
	public String getVariable() {
		return variable;
	}
	public void setVariable(String variable) {
		this.variable = variable;
	}
	@Override
	public String toString() {
		return "SliderConfig [defaultMin=" + defaultMin + ", defaultMax=" + defaultMax + ", defaultValue="
				+ defaultValue + ", variable=" + variable + "]";
	}
	
	
}
