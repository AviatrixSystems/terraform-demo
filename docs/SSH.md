How to SSH to your demo control instance
----------------------------------------
* On Mac:
  open Terminal app (command + space, type Terminal and hit enter)

  run: `ssh ubuntu@demo.<your username here>.aviatrix.live`

* On Windows:
  1. run Putty
  2. enter the following on the Session screen:
     - Host Name: `demo.<your username here>.aviatrix.live`
     - Port: 22 (default)
     - Connection type: SSH

    [Image](images/ssh/putty1.png)

   3. click on `Data` below `Connection` heading
   4. enter the following:
     - Username: `ubuntu`
 
    [Image](images/ssh/putty2.png)

   5. click on `SSH` below the `Connection` heading
   6. click on `Auth` below the `SSH` heading
   7. browse for your private SSH key and click Open

    [Image](images/ssh/putty3.png)

   8. return to the `Session`
   9. enter a name in the field just below `Saved Sessions`
   10. click `Save`

    [Image](images/ssh/putty4.png)
 
   11. click the saved session
   12. click `Open`
     
