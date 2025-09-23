@isTest
public with sharing class ARC_NumberToWordTest {

    @isTest
    static void testNumber() {
        System.assertEquals('ONE HUNDRED', ARC_NumberToWord.convert_nn(100).toUpperCase());
        System.assertEquals('ONE THOUSAND, ONE HUNDRED TWENTY EIGHT', ARC_NumberToWord.english_number(1128).toUpperCase());
        System.assertEquals('NINETY SIX MILLION, FIVE HUNDRED EIGHTY FIVE THOUSAND, THREE HUNDRED SIXTY SIX', ARC_NumberToWord.english_number(96585366).toUpperCase());
    }
}