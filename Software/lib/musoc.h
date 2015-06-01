//==================================================================================================
//  Filename      : musoc.h
//  Created On    : 2015-01-31
//  Last Modified : 2015-01-31
//  Revision      : 0
//  Author(s)     : Said Alvarado       (11-10025)
//                : Cristhian Bravo     (11-10124)
//                  Angel Terrones
//  Company       : Universidad Simón Bolívar
//
//  Description   : MUSoC registers.
//==================================================================================================


#ifndef _MUSOC_H
#define _MUSOC_H

/*########################################################################*/
/*                              Typedef                                   */
/*########################################################################*/
typedef volatile unsigned char byte;
typedef unsigned int word;

typedef union{
    byte Byte;
    struct {
        byte B0       :1;                                       /* GPIO Register Bit 0 */
        byte B1       :1;                                       /* GPIO Register Bit 1 */
        byte B2       :1;                                       /* GPIO Register Bit 2 */
        byte B3       :1;                                       /* GPIO Register Bit 3 */
        byte B4       :1;                                       /* GPIO Register Bit 4 */
        byte B5       :1;                                       /* GPIO Register Bit 5 */
        byte B6       :1;                                       /* GPIO Register Bit 6 */
        byte B7       :1;                                       /* GPIO Register Bit 7 */
    } Bits;
  } _GPIOreg;


/*########################################################################*/
/*                                GPIO                                    */
/*########################################################################*/

/*** PTAD - Port A Data Register; 0x10000000 ***/

#define _PTAD  (*(_GPIOreg *) 0x10000000)

#define PTAD_PTAD0  _PTAD.Bits.B0
#define PTAD_PTAD1  _PTAD.Bits.B1
#define PTAD_PTAD2  _PTAD.Bits.B2
#define PTAD_PTAD3  _PTAD.Bits.B3
#define PTAD_PTAD4  _PTAD.Bits.B4
#define PTAD_PTAD5  _PTAD.Bits.B5
#define PTAD_PTAD6  _PTAD.Bits.B6
#define PTAD_PTAD7  _PTAD.Bits.B7

#define PTAD        _PTAD.Byte



/*** PTBD - Port B Data Register; 0x10000001 ***/

#define _PTBD       (*(_GPIOreg *) 0x10000001)

#define PTBD_PTBD0  _PTBD.Bits.B0
#define PTBD_PTBD1  _PTBD.Bits.B1
#define PTBD_PTBD2  _PTBD.Bits.B2
#define PTBD_PTBD3  _PTBD.Bits.B3
#define PTBD_PTBD4  _PTBD.Bits.B4
#define PTBD_PTBD5  _PTBD.Bits.B5
#define PTBD_PTBD6  _PTBD.Bits.B6
#define PTBD_PTBD7  _PTBD.Bits.B7

#define PTBD        _PTBD.Byte



/*** PTCD - Port C Data Register; 0x10000002 ***/

#define _PTCD       (*(_GPIOreg *) 0x10000002)

#define PTCD_PTCD0  _PTCD.Bits.B0
#define PTCD_PTCD1  _PTCD.Bits.B1
#define PTCD_PTCD2  _PTCD.Bits.B2
#define PTCD_PTCD3  _PTCD.Bits.B3
#define PTCD_PTCD4  _PTCD.Bits.B4
#define PTCD_PTCD5  _PTCD.Bits.B5
#define PTCD_PTCD6  _PTCD.Bits.B6
#define PTCD_PTCD7  _PTCD.Bits.B7

#define PTCD        _PTCD.Byte



/*** PTDD - Port D Data Register; 0x10000003 ***/

#define _PTDD       (*(_GPIOreg *) 0x10000003)

#define PTDD_PTDD0  _PTDD.Bits.B0
#define PTDD_PTDD1  _PTDD.Bits.B1
#define PTDD_PTDD2  _PTDD.Bits.B2
#define PTDD_PTDD3  _PTDD.Bits.B3
#define PTDD_PTDD4  _PTDD.Bits.B4
#define PTDD_PTDD5  _PTDD.Bits.B5
#define PTDD_PTDD6  _PTDD.Bits.B6
#define PTDD_PTDD7  _PTDD.Bits.B7

#define PTDD        _PTDD.Byte



/*** PTADD - Port A Data Direction Register; 0x10000004 ***/

#define _PTADD          (*(_GPIOreg *) 0x10000004)

#define PTADD_PTADD0    _PTADD.Bits.B0
#define PTADD_PTADD1    _PTADD.Bits.B1
#define PTADD_PTADD2    _PTADD.Bits.B2
#define PTADD_PTADD3    _PTADD.Bits.B3
#define PTADD_PTADD4    _PTADD.Bits.B4
#define PTADD_PTADD5    _PTADD.Bits.B5
#define PTADD_PTADD6    _PTADD.Bits.B6
#define PTADD_PTADD7    _PTADD.Bits.B7

#define PTADD           _PTADD.Byte



/*** PTBDD - Port B Data Direction Register; 0x10000005 ***/

#define _PTBDD          (*(_GPIOreg *) 0x10000005)

#define PTBDD_PTBDD0    _PTBDD.Bits.B0
#define PTBDD_PTBDD1    _PTBDD.Bits.B1
#define PTBDD_PTBDD2    _PTBDD.Bits.B2
#define PTBDD_PTBDD3    _PTBDD.Bits.B3
#define PTBDD_PTBDD4    _PTBDD.Bits.B4
#define PTBDD_PTBDD5    _PTBDD.Bits.B5
#define PTBDD_PTBDD6    _PTBDD.Bits.B6
#define PTBDD_PTBDD7    _PTBDD.Bits.B7

#define PTBDD           _PTBDD.Byte



/*** PTCDD - Port C Data Direction Register; 0x10000006 ***/

#define _PTCDD          (*(_GPIOreg *) 0x10000006)

#define PTCDD_PTCDD0    _PTCDD.Bits.B0
#define PTCDD_PTCDD1    _PTCDD.Bits.B1
#define PTCDD_PTCDD2    _PTCDD.Bits.B2
#define PTCDD_PTCDD3    _PTCDD.Bits.B3
#define PTCDD_PTCDD4    _PTCDD.Bits.B4
#define PTCDD_PTCDD5    _PTCDD.Bits.B5
#define PTCDD_PTCDD6    _PTCDD.Bits.B6
#define PTCDD_PTCDD7    _PTCDD.Bits.B7

#define PTCDD           _PTCDD.Byte



/*** PTDDD - Port D Data Direction Register; 0x10000007 ***/

#define _PTDDD  (*(_GPIOreg *) 0x10000007)

#define PTDDD_PTDDD0    _PTDDD.Bits.B0
#define PTDDD_PTDDD1    _PTDDD.Bits.B1
#define PTDDD_PTDDD2    _PTDDD.Bits.B2
#define PTDDD_PTDDD3    _PTDDD.Bits.B3
#define PTDDD_PTDDD4    _PTDDD.Bits.B4
#define PTDDD_PTDDD5    _PTDDD.Bits.B5
#define PTDDD_PTDDD6    _PTDDD.Bits.B6
#define PTDDD_PTDDD7    _PTDDD.Bits.B7

#define PTDDD           _PTDDD.Byte



/*** PTAIE - Port A Interrupt Enable Register; 0x10000008 ***/

#define _PTAIE  (*(_GPIOreg *) 0x10000008)

#define PTAIE_PTDIE0    _PTAIE.Bits.B0
#define PTAIE_PTDIE1    _PTAIE.Bits.B1
#define PTAIE_PTDIE2    _PTAIE.Bits.B2
#define PTAIE_PTDIE3    _PTAIE.Bits.B3
#define PTAIE_PTDIE4    _PTAIE.Bits.B4
#define PTAIE_PTDIE5    _PTAIE.Bits.B5
#define PTAIE_PTDIE6    _PTAIE.Bits.B6
#define PTAIE_PTDIE7    _PTAIE.Bits.B7

#define PTAIE           _PTAIE.Byte



/*** PTBIE - Port B Interrupt Enable Register; 0x10000009 ***/

#define _PTBIE  (*(_GPIOreg *) 0x10000009)

#define PTBIE_PTDIE0    _PTBIE.Bits.B0
#define PTBIE_PTDIE1    _PTBIE.Bits.B1
#define PTBIE_PTDIE2    _PTBIE.Bits.B2
#define PTBIE_PTDIE3    _PTBIE.Bits.B3
#define PTBIE_PTDIE4    _PTBIE.Bits.B4
#define PTBIE_PTDIE5    _PTBIE.Bits.B5
#define PTBIE_PTDIE6    _PTBIE.Bits.B6
#define PTBIE_PTDIE7    _PTBIE.Bits.B7

#define PTBIE           _PTBIE.Byte



/*** PTCIE - Port C Interrupt Enable Register; 0x1000000A ***/

#define _PTCIE  (*(_GPIOreg *) 0x1000000A)

#define PTCIE_PTCIE0    _PTCIE.Bits.B0
#define PTCIE_PTCIE1    _PTCIE.Bits.B1
#define PTCIE_PTCIE2    _PTCIE.Bits.B2
#define PTCIE_PTCIE3    _PTCIE.Bits.B3
#define PTCIE_PTCIE4    _PTCIE.Bits.B4
#define PTCIE_PTCIE5    _PTCIE.Bits.B5
#define PTCIE_PTCIE6    _PTCIE.Bits.B6
#define PTCIE_PTCIE7    _PTCIE.Bits.B7

#define PTCIE           _PTCIE.Byte



/*** PTDIE - Port D Interrupt Enable Register; 0x1000000B ***/

#define _PTDIE  (*(_GPIOreg *) 0x1000000B)

#define PTDIE_PTDIE0    _PTDIE.Bits.B0
#define PTDIE_PTDIE1    _PTDIE.Bits.B1
#define PTDIE_PTDIE2    _PTDIE.Bits.B2
#define PTDIE_PTDIE3    _PTDIE.Bits.B3
#define PTDIE_PTDIE4    _PTDIE.Bits.B4
#define PTDIE_PTDIE5    _PTDIE.Bits.B5
#define PTDIE_PTDIE6    _PTDIE.Bits.B6
#define PTDIE_PTDIE7    _PTDIE.Bits.B7

#define PTDIE           _PTDIE.Byte



/*** PTAEP - Port A Edge Polarity Register; 0x1000000C ***/

#define _PTAEP  (*(_GPIOreg *) 0x1000000C)

#define PTAEP_PTDEP0    _PTAEP.Bits.B0
#define PTAEP_PTDEP1    _PTAEP.Bits.B1
#define PTAEP_PTDEP2    _PTAEP.Bits.B2
#define PTAEP_PTDEP3    _PTAEP.Bits.B3
#define PTAEP_PTDEP4    _PTAEP.Bits.B4
#define PTAEP_PTDEP5    _PTAEP.Bits.B5
#define PTAEP_PTDEP6    _PTAEP.Bits.B6
#define PTAEP_PTDEP7    _PTAEP.Bits.B7

#define PTAEP           _PTAEP.Byte



/*** PTBEP - Port B Edge Polarity Register; 0x1000000D ***/

#define _PTBEP  (*(_GPIOreg *) 0x1000000D)

#define PTBEP_PTDEP0    _PTBEP.Bits.B0
#define PTBEP_PTDEP1    _PTBEP.Bits.B1
#define PTBEP_PTDEP2    _PTBEP.Bits.B2
#define PTBEP_PTDEP3    _PTBEP.Bits.B3
#define PTBEP_PTDEP4    _PTBEP.Bits.B4
#define PTBEP_PTDEP5    _PTBEP.Bits.B5
#define PTBEP_PTDEP6    _PTBEP.Bits.B6
#define PTBEP_PTDEP7    _PTBEP.Bits.B7

#define PTBEP           _PTBEP.Byte



/*** PTCEP - Port C Edge Polarity Register; 0x1000000E ***/

#define _PTCEP  (*(_GPIOreg *) 0x1000000E)

#define PTCEP_PTCEP0    _PTCEP.Bits.B0
#define PTCEP_PTCEP1    _PTCEP.Bits.B1
#define PTCEP_PTCEP2    _PTCEP.Bits.B2
#define PTCEP_PTCEP3    _PTCEP.Bits.B3
#define PTCEP_PTCEP4    _PTCEP.Bits.B4
#define PTCEP_PTCEP5    _PTCEP.Bits.B5
#define PTCEP_PTCEP6    _PTCEP.Bits.B6
#define PTCEP_PTCEP7    _PTCEP.Bits.B7

#define PTCEP           _PTCEP.Byte



/*** PTDEP - Port D Edge Polarity Register; 0x1000000F ***/

#define _PTDEP  (*(_GPIOreg *) 0x1000000F)

#define PTDEP_PTDEP0    _PTDEP.Bits.B0
#define PTDEP_PTDEP1    _PTDEP.Bits.B1
#define PTDEP_PTDEP2    _PTDEP.Bits.B2
#define PTDEP_PTDEP3    _PTDEP.Bits.B3
#define PTDEP_PTDEP4    _PTDEP.Bits.B4
#define PTDEP_PTDEP5    _PTDEP.Bits.B5
#define PTDEP_PTDEP6    _PTDEP.Bits.B6
#define PTDEP_PTDEP7    _PTDEP.Bits.B7

#define PTDEP           _PTDEP.Byte



/*** PTAIC - Port A Clear Interrupt Register; 0x10000010 ***/

#define _PTAIC  (*(_GPIOreg *) 0x10000010)

#define PTAIC_PTDIC0    _PTAIC.Bits.B0
#define PTAIC_PTDIC1    _PTAIC.Bits.B1
#define PTAIC_PTDIC2    _PTAIC.Bits.B2
#define PTAIC_PTDIC3    _PTAIC.Bits.B3
#define PTAIC_PTDIC4    _PTAIC.Bits.B4
#define PTAIC_PTDIC5    _PTAIC.Bits.B5
#define PTAIC_PTDIC6    _PTAIC.Bits.B6
#define PTAIC_PTDIC7    _PTAIC.Bits.B7

#define PTAIC           _PTAIC.Byte



/*** PTBIC - Port B Clear Interrupt Register; 0x10000011 ***/

#define _PTBIC  (*(_GPIOreg *) 0x10000011)

#define PTBIC_PTDIC0    _PTBIC.Bits.B0
#define PTBIC_PTDIC1    _PTBIC.Bits.B1
#define PTBIC_PTDIC2    _PTBIC.Bits.B2
#define PTBIC_PTDIC3    _PTBIC.Bits.B3
#define PTBIC_PTDIC4    _PTBIC.Bits.B4
#define PTBIC_PTDIC5    _PTBIC.Bits.B5
#define PTBIC_PTDIC6    _PTBIC.Bits.B6
#define PTBIC_PTDIC7    _PTBIC.Bits.B7

#define PTBIC           _PTBIC.Byte



/*** PTCIC - Port C Clear Interrupt Register; 0x10000012 ***/

#define _PTCIC  (*(_GPIOreg *) 0x10000012)

#define PTCIC_PTCIC0    _PTCIC.Bits.B0
#define PTCIC_PTCIC1    _PTCIC.Bits.B1
#define PTCIC_PTCIC2    _PTCIC.Bits.B2
#define PTCIC_PTCIC3    _PTCIC.Bits.B3
#define PTCIC_PTCIC4    _PTCIC.Bits.B4
#define PTCIC_PTCIC5    _PTCIC.Bits.B5
#define PTCIC_PTCIC6    _PTCIC.Bits.B6
#define PTCIC_PTCIC7    _PTCIC.Bits.B7

#define PTCIC           _PTCIC.Byte



/*** PTDIC - Port D Clear Interrupt Register; 0x10000013 ***/

#define _PTDIC  (*(_GPIOreg *) 0x10000013)

#define PTDIC_PTDIC0    _PTDIC.Bits.B0
#define PTDIC_PTDIC1    _PTDIC.Bits.B1
#define PTDIC_PTDIC2    _PTDIC.Bits.B2
#define PTDIC_PTDIC3    _PTDIC.Bits.B3
#define PTDIC_PTDIC4    _PTDIC.Bits.B4
#define PTDIC_PTDIC5    _PTDIC.Bits.B5
#define PTDIC_PTDIC6    _PTDIC.Bits.B6
#define PTDIC_PTDIC7    _PTDIC.Bits.B7

#define PTDIC           _PTDIC.Byte

/*########################################################################*/
/*                                UART                                    */
/*########################################################################*/

/*** BUFFER - TX/RX Serial Buffer (in & out); 0x11000000 ***/

#define _BUFFER     (*(_GPIOreg *) 0x11000000)

#define BUFFER_B0   _BUFFER.Bits.B0
#define BUFFER_B1   _BUFFER.Bits.B1
#define BUFFER_B2   _BUFFER.Bits.B2
#define BUFFER_B3   _BUFFER.Bits.B3
#define BUFFER_B4   _BUFFER.Bits.B4
#define BUFFER_B5   _BUFFER.Bits.B5
#define BUFFER_B6   _BUFFER.Bits.B6
#define BUFFER_B7   _BUFFER.Bits.B7

#define BUFFER      _BUFFER.Byte



/*** TX_COUNT_L - TX buffer counter LOW; 0x11000001 ***/

#define _TX_COUNT_L     (*(_GPIOreg *) 0x11000001)

#define TX_COUNT_L_B0   _TX_COUNT_L.Bits.B0
#define TX_COUNT_L_B1   _TX_COUNT_L.Bits.B1
#define TX_COUNT_L_B2   _TX_COUNT_L.Bits.B2
#define TX_COUNT_L_B3   _TX_COUNT_L.Bits.B3
#define TX_COUNT_L_B4   _TX_COUNT_L.Bits.B4
#define TX_COUNT_L_B5   _TX_COUNT_L.Bits.B5
#define TX_COUNT_L_B6   _TX_COUNT_L.Bits.B6
#define TX_COUNT_L_B7   _TX_COUNT_L.Bits.B7

#define TX_COUNT_L      _TX_COUNT_L.Byte



/*** TX_COUNT_H - TX buffer counter HIGH; 0x11000002 ***/

#define _TX_COUNT_H     (*(_GPIOreg *) 0x11000002)

#define TX_COUNT_H_B0   _TX_COUNT_H.Bits.B0
#define TX_COUNT_H_B1   _TX_COUNT_H.Bits.B1
#define TX_COUNT_H_B2   _TX_COUNT_H.Bits.B2
#define TX_COUNT_H_B3   _TX_COUNT_H.Bits.B3
#define TX_COUNT_H_B4   _TX_COUNT_H.Bits.B4
#define TX_COUNT_H_B5   _TX_COUNT_H.Bits.B5
#define TX_COUNT_H_B6   _TX_COUNT_H.Bits.B6
#define TX_COUNT_H_B7   _TX_COUNT_H.Bits.B7

#define TX_COUNT_H      _TX_COUNT_H.Byte



/*** RX_COUNT_L - RX buffer counter LOW; 0x11000003 ***/

#define _RX_COUNT_L     (*(_GPIOreg *) 0x11000003)

#define RX_COUNT_L_B0   _RX_COUNT_L.Bits.B0
#define RX_COUNT_L_B1   _RX_COUNT_L.Bits.B1
#define RX_COUNT_L_B2   _RX_COUNT_L.Bits.B2
#define RX_COUNT_L_B3   _RX_COUNT_L.Bits.B3
#define RX_COUNT_L_B4   _RX_COUNT_L.Bits.B4
#define RX_COUNT_L_B5   _RX_COUNT_L.Bits.B5
#define RX_COUNT_L_B6   _RX_COUNT_L.Bits.B6
#define RX_COUNT_L_B7   _RX_COUNT_L.Bits.B7

#define RX_COUNT_L      _RX_COUNT_L.Byte



/*** RX_COUNT_H - RX buffer counter HIGH; 0x11000004 ***/

#define _RX_COUNT_H     (*(_GPIOreg *) 0x11000004)

#define RX_COUNT_H_B0   _RX_COUNT_H.Bits.B0
#define RX_COUNT_H_B1   _RX_COUNT_H.Bits.B1
#define RX_COUNT_H_B2   _RX_COUNT_H.Bits.B2
#define RX_COUNT_H_B3   _RX_COUNT_H.Bits.B3
#define RX_COUNT_H_B4   _RX_COUNT_H.Bits.B4
#define RX_COUNT_H_B5   _RX_COUNT_H.Bits.B5
#define RX_COUNT_H_B6   _RX_COUNT_H.Bits.B6
#define RX_COUNT_H_B7   _RX_COUNT_H.Bits.B7

#define RX_COUNT_H      _RX_COUNT_H.Byte


#endif  // _MUSOC_H
/**
 * End of file
 */
