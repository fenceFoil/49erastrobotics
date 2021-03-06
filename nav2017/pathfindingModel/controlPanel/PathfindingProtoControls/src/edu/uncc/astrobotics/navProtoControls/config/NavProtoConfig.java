package edu.uncc.astrobotics.navProtoControls.config;

import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.IOException;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.LinkedList;
import java.util.List;

import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComponent;
import javax.swing.JPanel;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.ObjectMapper;

import edu.uncc.astrobotics.navProtoControls.JNavValueSlider;
import edu.uncc.astrobotics.navProtoControls.VisualizerClient;

public class NavProtoConfig {
	private List<SliderConfig> sliders;
	private List<ButtonConfig> buttons;
	private List<CheckboxConfig> checkboxes;

	public static NavProtoConfig readConfig() {
		// read json file data to String
		byte[] jsonData = null;
		try {
			try {
				jsonData = Files.readAllBytes(Paths.get(NavProtoConfig.class.getResource("sliders.json").toURI()));
			} catch (URISyntaxException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return null;
		}

		// create ObjectMapper instance
		JsonFactory f = new JsonFactory();
		f.enable(JsonParser.Feature.ALLOW_COMMENTS);
		ObjectMapper objectMapper = new ObjectMapper(f);

		// convert json string to object
		try {
			return objectMapper.readValue(jsonData, NavProtoConfig.class);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return null;
		}
	}

	public List<JComponent> createControls() {
		LinkedList<JComponent> controls = new LinkedList<>();

		for (ButtonConfig config : buttons) {
			JPanel buttonPanel = new JPanel();
			buttonPanel.setLayout(new FlowLayout());

			JButton button = new JButton(config.getLabel());
			button.addActionListener(new ActionListener() {

				@Override
				public void actionPerformed(ActionEvent e) {
					VisualizerClient.sendCode(config.getCode());
				}
			});
			buttonPanel.add(button);

			controls.add(buttonPanel);
		}

		for (CheckboxConfig config : checkboxes) {
			JPanel buttonPanel = new JPanel();
			buttonPanel.setLayout(new FlowLayout());

			JCheckBox checkbox = new JCheckBox(config.getLabel());
			// Send default checkbox value to visualizer
			VisualizerClient.updateVariable(config.getVariable(), config.getDefaultValue());
			checkbox.setSelected(config.getDefaultValue());
			checkbox.addActionListener(new ActionListener() {

				@Override
				public void actionPerformed(ActionEvent e) {
					VisualizerClient.updateVariable(config.getVariable(), checkbox.getSelectedObjects() != null);
				}
			});
			buttonPanel.add(checkbox);

			controls.add(buttonPanel);
		}

		for (SliderConfig config : sliders) {
			JNavValueSlider slider = new JNavValueSlider(config.getVariable(), config.getDefaultMin(),
					config.getDefaultMax(), config.getDefaultValue());
			controls.add(slider);
		}

		return controls;
	}

	@Override
	public String toString() {
		return "NavProtoConfig [sliders=" + sliders + ", buttons=" + buttons + ", checkboxes=" + checkboxes + "]";
	}

	public List<ButtonConfig> getButtons() {
		return buttons;
	}

	public void setButtons(List<ButtonConfig> buttons) {
		this.buttons = buttons;
	}

	public List<CheckboxConfig> getCheckboxes() {
		return checkboxes;
	}

	public void setCheckboxes(List<CheckboxConfig> checkboxes) {
		this.checkboxes = checkboxes;
	}

	public List<SliderConfig> getSliders() {
		return sliders;
	}

	public void setSliders(List<SliderConfig> sliders) {
		this.sliders = sliders;
	}

	public static void main(String[] args) {
		System.out.println(readConfig());
	}
}
