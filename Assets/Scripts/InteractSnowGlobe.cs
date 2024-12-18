using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InteractSnowGlobe : MonoBehaviour
{
    public Animator animator;
    public ParticleSystem envirSnowParticles;
    public ParticleSystem interactSnowParticles;

    private void Start()
    {
        animator = GetComponent<Animator>();
    }


    public void Shake()
    {
        animator.SetTrigger("Shake");
        envirSnowParticles.Play();
        interactSnowParticles.Play();
    }

    IEnumerator DisableShake()
    {
        yield return new WaitForSeconds(.2f);
        animator.SetBool("Shaking", false);

    }
}
