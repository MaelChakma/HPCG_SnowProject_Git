using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(CharacterController))]
public class PlayerMovement : MonoBehaviour
{
    public enum State
    {
        walkMode,
        UIMode
    }

    public Camera playerCamera;
    public float walkSpeed = 6f;
    public float runSpeed = 12f;
    public float jumpPower = 7f;
    public float gravity = 10f;
    public float lookSpeed = 2f;
    public float lookXLimit = 45f;
    public float defaultHeight = 2f;
    public float crouchHeight = 1f;
    public float crouchSpeed = 3f;
    public State currentState = State.walkMode;
    public float maxFOV = 60f;
    public float minFOV = 10f;
    public float maxLookSpeed = 1f;
    public float minLookSpeed = 0.5f;
    public float zoomPower = 3f;
    public GameObject UIPanel;

    private Vector3 moveDirection = Vector3.zero;
    private float rotationX = 0;
    private CharacterController characterController;

    public bool canMove = true;
    private bool isSwitchingMovement;

    void Start()
    {
        characterController = GetComponent<CharacterController>();
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    void Update()
    {
        characterController.detectCollisions = false;
        CheckState();
        Zoom();

        switch (currentState)
        {
            case State.walkMode:
                Walk(); 
                break;
            case State.UIMode:
                UIMode();
                break;
        }
    }


    private void Walk()
    {
        Cursor.visible = false;
        Cursor.lockState = CursorLockMode.Locked;
        UIPanel.SetActive(false);

        Vector3 forward = transform.TransformDirection(Vector3.forward);
        Vector3 right = transform.TransformDirection(Vector3.right);
        bool isRunning = Input.GetKey(KeyCode.LeftShift);
        float curSpeedX = canMove ? (isRunning ? runSpeed : walkSpeed) * Input.GetAxis("Vertical") : 0;
        float curSpeedY = canMove ? (isRunning ? runSpeed : walkSpeed) * Input.GetAxis("Horizontal") : 0;
        float movementDirectionY = moveDirection.y;
        moveDirection = (forward * curSpeedX) + (right * curSpeedY);
        

        if (Input.GetButton("Jump") && canMove && characterController.isGrounded)
        {
            moveDirection.y = jumpPower;
        }
        else
        {
            moveDirection.y = movementDirectionY;
        }

        if (!characterController.isGrounded)
        {
            moveDirection.y -= gravity * Time.deltaTime;
        }

        if (Input.GetKey(KeyCode.R) && canMove)
        {
            characterController.height = crouchHeight;
            walkSpeed = crouchSpeed;
            runSpeed = crouchSpeed;

        }
        else
        {
            characterController.height = defaultHeight;
            walkSpeed = 6f;
            runSpeed = 12f;
        }

        characterController.Move(moveDirection * Time.deltaTime);

        if (canMove)
        {
            rotationX += -Input.GetAxis("Mouse Y") * lookSpeed;
            rotationX = Mathf.Clamp(rotationX, -lookXLimit, lookXLimit);
            playerCamera.transform.localRotation = Quaternion.Euler(rotationX, 0, 0);
            transform.rotation *= Quaternion.Euler(0, Input.GetAxis("Mouse X") * lookSpeed, 0);
        }
    }

    private void UIMode()
    {
        Cursor.visible = true;
        Cursor.lockState = CursorLockMode.None;
        UIPanel.SetActive(true);
  
    }



    private void CheckState()
    {
        if (Input.GetKeyDown(KeyCode.F) && !isSwitchingMovement)
        {
            currentState = currentState == State.walkMode ? State.UIMode : State.walkMode;
        }
    }

    private void Zoom()
    {
        float delta = Input.mouseScrollDelta.y;
        playerCamera.fieldOfView = Mathf.Clamp(playerCamera.fieldOfView - delta * zoomPower,minFOV, maxFOV);
        lookSpeed = Mathf.Clamp(lookSpeed - delta / 10, minLookSpeed, maxLookSpeed);
    }


}