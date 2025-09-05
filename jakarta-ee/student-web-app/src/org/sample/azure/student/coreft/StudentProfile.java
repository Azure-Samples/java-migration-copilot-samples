package org.sample.azure.student.coreft;

import java.io.Serializable;

/**
 * Entity class representing a student profile.
 * Contains basic information about a student including ID, name, email, and major.
 */
public class StudentProfile implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    private int id;
    private String name;
    private String email;
    private String major;

    /**
     * Default constructor for StudentProfile.
     */
    public StudentProfile() {
    }

    /**
     * Constructor with all fields.
     * 
     * @param id the student ID
     * @param name the student name
     * @param email the student email
     * @param major the student major
     */
    public StudentProfile(int id, String name, String email, String major) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.major = major;
    }

    /**
     * Gets the student ID.
     * 
     * @return the student ID
     */
    public int getId() {
        return id;
    }

    /**
     * Sets the student ID.
     * 
     * @param id the student ID to set
     */
    public void setId(int id) {
        this.id = id;
    }

    /**
     * Gets the student name.
     * 
     * @return the student name
     */
    public String getName() {
        return name;
    }

    /**
     * Sets the student name.
     * 
     * @param name the student name to set
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Gets the student email.
     * 
     * @return the student email
     */
    public String getEmail() {
        return email;
    }

    /**
     * Sets the student email.
     * 
     * @param email the student email to set
     */
    public void setEmail(String email) {
        this.email = email;
    }

    /**
     * Gets the student major.
     * 
     * @return the student major
     */
    public String getMajor() {
        return major;
    }

    /**
     * Sets the student major.
     * 
     * @param major the student major to set
     */
    public void setMajor(String major) {
        this.major = major;
    }

    @Override
    public String toString() {
        return "StudentProfile{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", email='" + email + '\'' +
                ", major='" + major + '\'' +
                '}';
    }
}
