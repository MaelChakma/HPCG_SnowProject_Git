using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UICanvas : MonoBehaviour
{
    public ParticleSystem snowParticleSystem;
    public Material snowParticleMaterial;

    public Toggle snowToggle;
    public Slider renderDistanceSlider;
    public Slider maxParticlesSlider;



    void Start()
    {
        var main = snowParticleSystem.main;

        snowToggle.onValueChanged.AddListener((b) =>
        {
            if (b) snowParticleSystem.Play();
            else snowParticleSystem.Pause();
        });
        renderDistanceSlider.onValueChanged.AddListener((v) =>
        {
            snowParticleMaterial.SetFloat("_SwitchDistance", v);
        });
        maxParticlesSlider.onValueChanged.AddListener((v) =>
        {
            main.maxParticles = Mathf.RoundToInt(v);
        });
    }

    public void QuitApp()
    {
        Application.Quit();
    }

    
}
