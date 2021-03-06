package edu.uncc.astrobotics.navProtoControls;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.Font;

import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JSlider;
import javax.swing.JSpinner;
import javax.swing.SpinnerNumberModel;
import javax.swing.SwingConstants;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;

public class JNavValueSlider extends JPanel {

	private String variable = "<<< NO VARIABLE ASSIGNED >>>";
	private JSlider slider;
	private JSpinner valueSpinner;
	private JSpinner maxSpinner;
	private JSpinner minSpinner;

	/**
	 * Create the panel.
	 */
	public JNavValueSlider(String variable, double minValue, double maxValue, double defaultValue) {
		this.variable = variable;

		setSize(new Dimension(500, 100));
		setLayout(new BorderLayout(0, 0));

		minSpinner = new JSpinner();
		minSpinner.setPreferredSize(new Dimension(70, 28));
		minSpinner.setModel(new SpinnerNumberModel(new Double(0), null, null, new Double(1)));
		minSpinner.setValue(minValue);
		minSpinner.addChangeListener(new ChangeListener() {

			@Override
			public void stateChanged(ChangeEvent arg0) {
				refreshSliderValue(true);
			}
		});
		add(minSpinner, BorderLayout.WEST);

		maxSpinner = new JSpinner();
		maxSpinner.setPreferredSize(new Dimension(70, 28));
		maxSpinner.setModel(new SpinnerNumberModel(new Double(0), null, null, new Double(1)));
		maxSpinner.setValue(maxValue);
		maxSpinner.addChangeListener(new ChangeListener() {

			@Override
			public void stateChanged(ChangeEvent arg0) {
				refreshSliderValue(true);
			}
		});
		add(maxSpinner, BorderLayout.EAST);

		JPanel topPanel = new JPanel();
		add(topPanel, BorderLayout.NORTH);

		JLabel variableLabel = new JLabel(variable);
		variableLabel.setFont(new Font("SansSerif", Font.BOLD, 16));
		variableLabel.setHorizontalTextPosition(SwingConstants.LEADING);
		topPanel.add(variableLabel);
		variableLabel.setHorizontalAlignment(SwingConstants.LEFT);

		JPanel spacer_panel_1 = new JPanel();
		spacer_panel_1.setPreferredSize(new Dimension(80, 10));
		spacer_panel_1.setMinimumSize(new Dimension(50, 10));
		topPanel.add(spacer_panel_1);

		valueSpinner = new JSpinner();
		valueSpinner.setPreferredSize(new Dimension(100, 28));
		valueSpinner.setModel(new SpinnerNumberModel(new Double(0), null, null, new Double(1)));
		valueSpinner.setValue(defaultValue);
		valueSpinner.addChangeListener(new ChangeListener() {

			@Override
			public void stateChanged(ChangeEvent arg0) {
				refreshSliderValue(true);
			}
		});
		topPanel.add(valueSpinner);

		slider = new JSlider();
		slider.setMaximum(32000);
		slider.setPaintTicks(true);
		slider.setPaintLabels(true);
		slider.addChangeListener(new ChangeListener() {

			@Override
			public void stateChanged(ChangeEvent arg0) {
				refreshSliderValue(false);
			}
		});
		add(slider);
		refreshSliderValue(true);

	}

	/**
	 * Updates values across JNavValueSlider, depending on whether the spinner
	 * values have changed or the slider has.
	 */
	protected void refreshSliderValue(boolean spinnersChanged) {
		if (spinnersChanged) {
			// Update slider
			double range = ((double) maxSpinner.getValue() - (double) minSpinner.getValue());
			double offset = (double) minSpinner.getValue();
			double value = (double) valueSpinner.getValue();
			double normalizedValue = (value - offset) / range;
			slider.setValue((int) Math.round(32000 * normalizedValue));
		} else {
			// Update spinners
			// Update value spinner
			valueSpinner.setValue(getSliderValue());
		}
		
		VisualizerClient.updateVariable(variable, getSliderValue());
	}

	public double getSliderValue() {
		return slider.getValue() / 32000d * ((double) maxSpinner.getValue() - (double) minSpinner.getValue())
				+ (double) minSpinner.getValue();
	}

}
